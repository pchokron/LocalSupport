require 'csv'
require 'mailchimp'

module MailchimpHelper

  def self.get_list(list_name)
    case list_name
      when 'OrganizationList'
        OrganizationList
      when 'UserList'
        UserList
      else
        raise(ArgumentError, "Request list (#{list_name}) is not valid.")
    end
  end

  class OrganizationList < Organization
    def self.to_csv(options = {})
      mailchimp_columns = %w(email id name description address postcode website telephone created_at updated_at donation_info has_admin)
      options[:headers] = :first_row
      CSV.generate(options) do |csv|
        csv << mailchimp_columns
        includes(:users).where("email <> ''").each do |org|
          row = org.attributes.select {|field,value| mailchimp_columns.include?(field )}
          row['has_admin'] = org.has_users? ? 'Yes' : 'No'
          csv << row
        end
      end
    end

    def self.to_mailchimp
      # TODO
      batch = includes(:users).where("email <> ''").map do |o|
        entry = {}
        entry['email'] = {'email' => o.email}
        entry['email_type'] = 'text'
        entry['merge_vars'] = {
            'MM_ID' => o.id,
            'MM_NAME' => o.name,
            'MM_DESC' => o.description,
            'MM_ADDR' => o.address,
            'MM_POST' => o.postcode,
            'MM_WEB' => o.website,
            'MM_TEL' => o.telephone,
            'MM_UPD' => o.updated_at,
            'MM_DONAT' => o.donation_info,
            'MM_HAS_ADM' => o.has_users? ? 'Yes' : 'No'
        }
        entry
      end
      batch
    end
  end

  class UserList < User
    def self.to_csv(options = {})
      mailchimp_columns = %w(email id admin organization_id current_sign_in_at created_at updated_at)
      options[:headers] = :first_row
      CSV.generate(options) do |csv|
        csv << mailchimp_columns
        all.each do |u|
          row = u.attributes.select {|field,value| mailchimp_columns.include?(field )}
          csv << row
        end
      end
    end

    def self.to_mailchimp
      batch = all.map do |u|
        entry = {}
        entry['email'] = {'email' => u.email}
        entry['email_type'] = 'text'
        entry['merge_vars'] = {
          'MM_ID' => u.id,
          'MM_ORG' => u.organization_id,
          'MM_UPD' => u.updated_at,
          'MM_ADM' => u.admin,
          'MM_LOGIN' => u.current_sign_in_at
        }
        entry
      end
      batch
    end
  end

  class Api
    attr_reader :api_error
    attr_reader :api_enabled
    attr_reader :results_added
    attr_reader :results_updated
    attr_reader :results_errors

    # Maps LocalSupport lists to Mailchimp
    # ** Should be pulled into a config file **
    @@list_map = {
        'OrganizationList' => 'LS Orgs Test List',
        'UserList' => 'LS Users Test List'
    }

    def initialize
      begin
        #@mc = Mailchimp::API.new('TESTING_BAD_KEY')
        @mc = Mailchimp::API.new(ENV['MAILCHIMP_API_KEY'])
        res = @mc.helper.ping
      rescue Exception => ex
        @api_error = "An error occurred.\n#{ex.try(:message)}"
      end
      @api_enabled = res && res.try(:has_key?,'msg') && res['msg'].include?("Everything's Chimpy!")
    end

    def update_list(list_name)
      list_id = get_list_id(list_name)
      batch = MailchimpHelper::get_list(list_name).to_mailchimp
      double_optin = :false # Do not send an opt-in confirmation email!
      update_existing = :true
      results = @mc.lists.batch_subscribe(list_id,batch,double_optin,update_existing)
      @results_added = results['add_count']
      @results_updated = results['update_count']
      @results_errors = results['error_count']
    end

  private

    def get_list_id(list_name)
      match = @mc.lists.list(filters = {:list_name => @@list_map[list_name]})
      unless match['total'] == 1
        raise ArgumentError.new('List not found.  Create list in MailChimp First')
      end
      match['data'][0]['id']
    end

  end

end
