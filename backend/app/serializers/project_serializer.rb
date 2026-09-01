# frozen_string_literal: true

module Backend
  module Serializers
    class ProjectSerializer
      include Alba::Resource

      attributes :name, :slug, :created_at, :updated_at

      attribute :id do |project|
        project.public_id
      end

      # params: { current_user: } - omitted (nil) when not provided. Alba
      # attribute blocks run via instance_exec with only the object as an
      # argument - `params` here is the resource's own attr_reader, not a
      # block param.
      attribute :my_role do |project|
        params[:current_user] && project.effective_role_for(params[:current_user])
      end
    end
  end
end
