#   Copyright (c) 2012-2017, Fairmondo eG.  This file is
#   licensed under the GNU Affero General Public License version 3 or later.
#   See the COPYRIGHT file for details.

class RewriteConfig
  def self.list
    []
  end
end

module Rack
  class Rewrite
    class FairmondoRuleSet
      attr_reader :rules

      def initialize(_options)
        @rules = RewriteConfig.list.map do |rule|
          Rule.new(rule[:method], rule[:from], rule[:to], if: rule[:if])
        end
      end
    end
  end
end
