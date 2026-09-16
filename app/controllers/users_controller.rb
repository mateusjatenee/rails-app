class UsersController < ApplicationController
  def index
    @users = load_users
    @environment = EnvironmentInfo.sections
  end

  private

  # The users table only exists when a real database is attached and migrated.
  # Without one, render an empty list instead of failing the whole page.
  def load_users
    return User.none unless User.table_exists?

    User.select(:id, :name, :email, :created_at).order(:id)
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.warn("Could not load users: #{e.class}: #{e.message}")
    User.none
  end
end
