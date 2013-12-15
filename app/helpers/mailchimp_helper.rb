require 'csv'

module MailchimpHelper

      # orgs = Organization.export_orphan_organization_emails
      #CSV.open("db/target_emails.csv", "wb") do |csv|
      #  orgs.each { |org| csv << [org.name, org.email] }
      #end

  def self.get_list(list_name)
    case list_name
      when 'OrganizationList'
        OrganizationList.to_csv
      when 'UserList'
        UserList.to_csv
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
  end

end
