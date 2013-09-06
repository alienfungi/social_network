class SessionsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]

  def new
  end

  def create
    email = params[:session][:email].downcase
    if User.authenticate(email, params[:session][:password])
      user = User.find_by_email(email)
      sign_in user
      redirect_to users_path, flash: { success: 'You are now logged in.' }
    else
      flash.now[:error] = 'Invalid login credentials'
      render 'new'
    end
  end

  def destroy
    sign_out
    redirect_to login_path, flash: { notice: 'You are now logged out.' }
  end

end
