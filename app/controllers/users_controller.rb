class UsersController < ApplicationController
  def index
    @users = User.select(:id, :name, :email, :created_at).order(:id)
    @environment = EnvironmentInfo.sections
  end
end
