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

module RedmineContacts
  module FieldFormat
    class AddressFormat < Redmine::FieldFormat::StringFormat
      add 'address'

      self.customized_class_names = nil
      self.multiple_supported = false
      self.bulk_edit_supported = false

      def edit_tag(view, tag_id, tag_name, custom_value, options = nil)
        render_address_tag(view, tag_id, tag_name, custom_value, options)
      end

      def related_object(custom_value)
        custom_value.address || custom_value.build_address
      end

      def validate_custom_value(custom_value)
        []
      end

      def set_custom_field_value(custom_field, custom_field_value, params)
        address = custom_field_value.related_object
        address.public_send(address.persisted? ? :update : :assign_attributes, params['address']) if params['address'].present?

        super(custom_field, custom_field_value, address.to_s)
      end

      private

      def render_address_tag(view, tag_id, tag_name, custom_value, options={})
        address = custom_value.related_object

        view.fields_for(tag_name) do |cf|
          cf.fields_for(address) do |f|
            view.render(partial: 'common/custom_field_address', locals: { f: f })
          end
        end
      end
    end
  end
end
