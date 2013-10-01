#
#
# == License:
# Fairnopoly - Fairnopoly is an open-source online marketplace.
# Copyright (C) 2013 Fairnopoly eG
#
# This file is part of Fairnopoly.
#
# Fairnopoly is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Fairnopoly is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Fairnopoly.  If not, see <http://www.gnu.org/licenses/>.
#
class Image < ActiveRecord::Base
  def self.image_attrs nested_attrs = false
    output = [:image, :is_title]
    output.push(:_destroy, :id) if nested_attrs
    output
  end
  #! attr_accessible *image_attributes
  #! attr_accessible *image_attributes, :as => :admin

  belongs_to :imageable, polymorphic: true #has_and_belongs_to_many :articles
  has_attached_file :image, styles: { medium: "520>x360>", thumb: "260x180#", profile: "300x300#" },
                            default_url: "/assets/missing.png",
                            url: "/system/:attachment/:id_partition/:style/:filename",
                            path: "public/system/:attachment/:id_partition/:style/:filename"

  default_scope order('created_at ASC')

  validates_attachment_presence :image
  validates_attachment_content_type :image,:content_type => ['image/jpeg', 'image/png', 'image/gif']
  validates_attachment_size :image, :in => 0..2.megabytes


  # Using polymorphy with STI (User) is tricky: http://api.rubyonrails.org/classes/ActiveRecord/Associations/ClassMethods.html#label-Polymorphic+Associations
  # @api public
  def imageable_type=(sType)
    super(sType.to_s.classify.constantize.base_class.to_s)
  end

  # Get The Geometry of a image
  #
  # Use the returned Object to get the Size of the image
  # geo = image.geometry :medium
  # geo.width
  # geo.height
  #
  # param style [Symbol] style of the image you want the dimensions of
  # return [Paperclip Geometry Object]
  def geometry style
     Paperclip::Geometry.from_file(self.image.path(style))
  end

end
