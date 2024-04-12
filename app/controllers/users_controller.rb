# frozen_string_literal: true

class UsersController < ApplicationController
  def create
    # TODO: Please extract into a method called require_user_params
    user_params = params.require(:user).permit(:name, :email, :password, :password_confirmation)

    # TODO: Can we process the password parameters on a dedicated function ? 
    password = user_params[:password].to_s.strip
    password_confirmation = user_params[:password_confirmation].to_s.strip

    errors = {}
    errors[:password] = ["can't be blank"] if password.blank? # TODO: Not necessary. Rails will handle this. I think?.
    errors[:password_confirmation] = ["can't be blank"] if password_confirmation.blank? # TODO: Same.

    if errors.present?
      render_json(422, user: errors)
    else
      # TODO: Can we make this check along with the password processing on a dedicated function, something like validate_password
      # This validation should happen at controller level. The model should also have it's own validation about the password, like requiring presence and certain charactersitics.
      if password != password_confirmation
        render_json(422, user: { password_confirmation: ["doesn't match password"] })
      else
        # TODO: Too much logic in this controller. Can we extract the responsiblity of knowing how to digest a password somewhere else ? and then at controller level just ask for it.
        password_digest = Digest::SHA256.hexdigest(password)

        user = User.new(
          name: user_params[:name],
          email: user_params[:email],
          token: SecureRandom.uuid, # TODO: Same as with the password_digest, the controller knows too much. Knowing that we need to use SecureRandom.uuid is too much for the controller. Can we maybe, do something like User.from(...) ?. Or a UserBuilder and UserBuilder.new.set_email =, .set_name = i, .set_password, .save and the the builder handles everything
          password_digest: password_digest
        )

        
        # TODO: I wonder if can instead invoke user.save! and then having rails handle the exception, instead of having to check if the user was saved or not.
        # TODO: Alternatively, If there isn't a mechanism to handle the exception, we could use a transaction to ensure that the user is saved, and if not, rollback the transaction. By addinga rescue_from clause at ApplicationController level
        if user.save
          render_json(201, user: user.as_json(only: [:id, :name, :token]))
        else
          render_json(422, user: user.errors.as_json)
        end
      end
    end
  end

  def show
    # TODO: Use a before action. It's also easier to forget to use the perform_if_authenticated method.
    perform_if_authenticated
  end

  def destroy
    # TODO: Use a before action, it's more readable.
    perform_if_authenticated do
      current_user.destroy
    end
  end

  private

    def perform_if_authenticated(&block)
      authenticate_user do
        block.call if block

        render_json(200, user: { email: current_user.email })
      end
    end
end
