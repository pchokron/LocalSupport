class AdminController < ApplicationController
  before_filter :authenticate_user!

  def mailchimp
    unless current_user.try(:admin?)
      redirect_to root_path
      flash[:alert] = PERMISSION_DENIED and return
    end

  end

  def mailchimp_export
    unless current_user.try(:admin?)
      redirect_to root_path
      flash[:alert] = PERMISSION_DENIED and return
    end
    respond_to do |format|
      format.html
      format.csv { send_data MailchimpHelper.get_list(params[:list]) }
    end
    #flash[:notice] = "Successfully exported #{params[:list]}.#{params[:format]}"
    #redirect_to '/admin/mailchimp'
  end

  def mailchimp_export_api
    unless current_user.try(:admin?)
      redirect_to root_path
      flash[:alert] = PERMISSION_DENIED and return
    end
    flash[:notice] = "Successfully exported #{params[:list]} to MailChimpAPI"
    redirect_to '/admin/mailchimp'
  end

end
