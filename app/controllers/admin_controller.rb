class AdminController < ApplicationController
  before_filter :authenticate_user!, :setup_mailchimp_api

end
