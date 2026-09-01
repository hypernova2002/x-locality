# frozen_string_literal: true

module Backend
  module Actions
    module API
      module V1
        module Admin
          module Projects
            module Locales
              class Import < Action
                params do
                  required(:project_id).filled(:string)
                  required(:format).filled(:string, included_in?: %w[csv json])
                  required(:content_base64).filled(:string)
                  optional(:compressed).filled(:bool)
                end

                def handle(request, response)
                  unless request.params.valid?
                    return render_problem(response, status: 422, title: 'Unprocessable Entity',
                                                    errors: request.params.errors.to_h)
                  end

                  compressed = request.params[:compressed]
                  compressed = true if compressed.nil?

                  result = Backend::Locales::Import.new.call(
                    project: project(request),
                    format: request.params[:format],
                    content_base64: request.params[:content_base64],
                    compressed: compressed
                  )

                  case result
                  in Success(summary)
                    response.format = :json
                    response.body = summary.to_json
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
  end
end
