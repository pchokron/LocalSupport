class Admin::MailchimpController < ApplicationController
  before_filter :authenticate_user!

  def index
    unless current_user.try(:admin?)
      redirect_to root_path
      flash[:alert] = PERMISSION_DENIED and return
    end
    mc = MailchimpHelper::Api.new
    @api_enabled = mc.api_enabled
    @api_error = mc.api_error
  end

  def export
    unless current_user.try(:admin?)
      redirect_to root_path
      flash[:alert] = PERMISSION_DENIED and return
    end
    respond_to do |format|
      format.html
      format.csv { send_data MailchimpHelper.get_list(params[:list]).to_csv }
    end
  end

  def export_api
    unless current_user.try(:admin?)
      redirect_to root_path
      flash[:alert] = PERMISSION_DENIED and return
    end
    mc = MailchimpHelper::Api.new
    @api_enabled = mc.api_enabled
    unless @api_enabled
      flash[:error] = 'Unable to connect to MailChimp API'
      redirect_to '/admin/mailchimp' and return
    end
    begin
      mc.update_list(params[:list])
      flash[:notice] = "Successfully exported #{params[:list]} to MailChimp\n(#{mc.results_added} records added; #{mc.results_updated} records updated; #{mc.results_errors} records generated errors; "
    rescue Exception => ex
      flash[:error] = "An error occurred.\n#{ex.try(:message)}"
    end
    redirect_to '/admin/mailchimp'
  end

end
