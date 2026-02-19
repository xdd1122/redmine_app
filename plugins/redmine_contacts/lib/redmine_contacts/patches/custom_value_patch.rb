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
  module Patches
    module CustomValuePatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          has_one :address, dependent: :delete, as: :addressable, class_name: 'Address'
        end
      end

      module InstanceMethods

      end
    end
  end
end

unless CustomValue.included_modules.include?(RedmineContacts::Patches::CustomValuePatch)
  CustomValue.send(:include, RedmineContacts::Patches::CustomValuePatch)
end
