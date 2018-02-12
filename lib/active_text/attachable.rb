module ActiveText
  module Attachable
    extend ActiveSupport::Concern

    LOCATOR_NAME = "attachable"

    class << self
      def from_node(node)
        if attachable = attachable_from_sgid(node["sgid"])
          attachable
        elsif attachable = ActiveText::Attachables::ContentAttachment.from_node(node)
          attachable
        elsif attachable = ActiveText::Attachables::RemoteImage.from_node(node)
          attachable
        else
          ActiveText::Attachables::MissingAttachable
        end
      end

      def from_attachable_sgid(sgid, options = {})
        method = sgid.is_a?(Array) ? :locate_many_signed : :locate_signed
        record = GlobalID::Locator.public_send(method, sgid, options.merge(for: LOCATOR_NAME))
        record or raise ActiveRecord::RecordNotFound
      end

      private
        def attachable_from_sgid(sgid)
          from_attachable_sgid(sgid)
        rescue ActiveRecord::RecordNotFound
          nil
        end
    end

    class_methods do
      def from_attachable_sgid(sgid)
        ActiveText::Attachable.from_attachable_sgid(sgid, only: self)
      end
    end

    def attachable_sgid
      to_sgid(expires_in: nil, for: LOCATOR_NAME).to_s
    end

    def attachable_content_type
      try(:content_type) || "application/octet-stream"
    end

    def previewable_attachable?
      false
    end

    def as_json(*)
      super.merge(attachable_sgid: attachable_sgid)
    end

    def to_active_text_attributes(attributes = {})
      attributes.dup.tap do |attributes|
        attributes[:sgid] = attachable_sgid
        attributes[:content_type] = attachable_content_type
        attributes[:previewable] = true if previewable_attachable?
      end
    end
  end
end
