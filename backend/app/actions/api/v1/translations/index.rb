# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Translations
          class Index < API::V1::Action
            params do
              optional(:locale).maybe(:string)
              optional(:key).maybe(:string)
              optional(:after).maybe(:integer)
              optional(:limit).maybe(:integer, gteq?: 1, lteq?: 200)
            end

            def handle(request, response)
              unless request.params.valid?
                return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                errors: request.params.errors.to_h)
              end

              result = Backend::Translations::List.new.call(
                project: current_project(request),
                locale_key: request.params[:locale],
                key_filter: request.params[:key],
                after: request.params[:after],
                limit: request.params[:limit] || 50
              )

              case result
              in Success(data)
                if data[:has_more]
                  next_url = "#{request.base_url}#{request.path}?#{Rack::Utils.build_query(request.params.to_h.merge(after: data[:records].last.id))}"
                  response.headers['Link'] = "<#{next_url}>; rel=\"next\""
                end

                response.format = :json
                response.body = Backend::Serializers::TranslationSerializer.new(data[:records]).serialize
              in Failure[code, detail]
                render_failure(response, code, detail)
              end
            end
          end
        end
      end
    end
  end
end
