# encoding: utf-8
#
# This file is a part of Redmine CRM (redmine_contacts) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2010-2026 RedmineUP
# http://www.redmineup.com/
#
# redmine_contacts is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_contacts is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_contacts.  If not, see <http://www.gnu.org/licenses/>.

require File.expand_path('../../test_helper', __FILE__)

class IssuesControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers,
           :time_entries,
           :journals,
           :journal_details,
           :queries

  RedmineContacts::TestCase.create_fixtures(Redmine::Plugin.find(:redmine_contacts).directory + '/test/fixtures/', [:contacts,
                                                                                                                    :contacts_projects,
                                                                                                                    :deals,
                                                                                                                    :notes,
                                                                                                                    :tags,
                                                                                                                    :taggings,
                                                                                                                    :queries,
                                                                                                                    :addresses])

  def setup
    RedmineContacts::TestCase.prepare
    User.current = nil
    @request.session[:user_id] = 1

    issue = Issue.find(1)
    contact = Contact.find(2)
    deal = Deal.find(1)
    @address_params = {'address' => {
      'street1' => 'Street1',
      'street2' => 'Street2',
      'city' => 'Moscow',
      'region' => 'Moscow',
      'postcode' => '110022',
      'country_code' => 'RU'
    }}

    # Warning: test_helper already creates some custom fields and custom values
    @contact_cf = IssueCustomField.create!(name: 'Related contacts',
                                           field_format: 'contact',
                                           is_filter: true,
                                           is_for_all: true,
                                           multiple: true,
                                           tracker_ids: Tracker.pluck(:id))
    @deal_cf = IssueCustomField.create!(name: 'Related deals',
                                        field_format: 'deal',
                                        is_filter: true,
                                        is_for_all: true,
                                        multiple: true,
                                        tracker_ids: Tracker.pluck(:id))
    @address_cf = issue.custom_field_values.select { |cf| cf.custom_field.field_format == 'address' }.first.custom_field

    CustomValue.create!(custom_field: @contact_cf, customized: issue, value: contact.id)
    CustomValue.create!(custom_field: @deal_cf, customized: issue, value: deal.id)
  end

  private

  def create_address_cf
    address_cf = CustomField.new_subclass_instance('IssueCustomField')
    address_cf.name = 'Addresses cf'
    address_cf.field_format = 'address'
    address_cf.is_for_all = true

    address_cf.tracker_ids = Tracker.pluck(:id)
    address_cf.save!
    address_cf
  end

  def create_issue
    Issue.create!(
      subject: 'New issue address',
      project_id: 1,
      tracker_id: 1,
      status_id: 1,
      priority_id: 4,
      author_id: 1
    )
  end
end
