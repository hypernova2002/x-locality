# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Translations API', type: :openapi do
  openapi_schema :public_api

  let(:project) { create(:project) }
  let(:plaintext_key) { "xloc_test_#{SecureRandom.hex(8)}" }
  let!(:api_key) { create(:api_key, project: project, plaintext_key: plaintext_key) }
  let(:target_locale) { create(:locale, project: project, key: 'fr') }

  path '/translations' do
    post 'Create or fetch translations' do
      tags 'Translations'
      security([{ 'BearerAuth' => [] }])
      consumes 'application/json'
      produces 'application/json'

      request_body required: true, content: {
        'application/json' => { schema: { '$ref' => '#/components/schemas/CreateTranslationsRequest' } }
      }

      response 200, 'returns a cached translation without calling the LLM' do
        schema type: :array, items: { '$ref' => '#/components/schemas/TranslationCreateResult' }

        let(:project) { create(:project, :with_llm_configured) }
        let(:Authorization) { "Bearer #{plaintext_key}" }
        let!(:existing) do
          create(:translation, project: project, locale: target_locale, key: 'greeting',
                               source_text: 'Hello', status: 'completed', translated_text: 'Bonjour')
        end
        let(:request_body) do
          { target_locales: [target_locale.key], items: [{ key: 'greeting', source_text: 'Hello' }] }
        end

        run_test! do
          expect(parsed_body.dig(0, 'translations', 0, 'cached')).to be(true)
          expect(parsed_body.dig(0, 'translations', 0, 'translated_text')).to eq('Bonjour')
        end
      end

      response 401, 'missing or invalid API key' do
        schema '$ref' => '#/components/schemas/ProblemDetails'

        let(:request_body) { { target_locales: ['fr'], items: [{ key: 'greeting', source_text: 'Hello' }] } }
        run_test!
      end

      response 422, 'request body fails validation' do
        schema '$ref' => '#/components/schemas/ValidationProblemDetails'

        let(:Authorization) { "Bearer #{plaintext_key}" }
        let(:request_body) { { target_locales: [], items: [] } }
        run_test!
      end
    end

    get 'List translations' do
      tags 'Translations'
      security([{ 'BearerAuth' => [] }])
      produces 'application/json'

      parameter name: :locale, in: :query, schema: { type: :string }, required: false,
                description: 'Filter to a single locale key.'
      parameter name: :key, in: :query, schema: { type: :string }, required: false,
                description: 'Filter to keys containing this substring.'
      parameter name: :after, in: :query, schema: { type: :integer }, required: false,
                description: 'Cursor: return records with an id greater than this.'
      parameter name: :limit, in: :query, schema: { type: :integer, minimum: 1, maximum: 200 }, required: false,
                description: 'Defaults to 50.'

      response 200, 'returns matching translations' do
        schema type: :array, items: { '$ref' => '#/components/schemas/Translation' }

        let(:Authorization) { "Bearer #{plaintext_key}" }
        let!(:existing) do
          create(:translation, project: project, locale: target_locale, key: 'greeting',
                               source_text: 'Hello', status: 'completed', translated_text: 'Bonjour')
        end

        run_test! do
          expect(parsed_body.first['key']).to eq('greeting')
        end
      end

      response 401, 'missing or invalid API key' do
        schema '$ref' => '#/components/schemas/ProblemDetails'
        run_test!
      end

      response 422, 'limit is out of range' do
        schema '$ref' => '#/components/schemas/ValidationProblemDetails'

        let(:Authorization) { "Bearer #{plaintext_key}" }
        let(:limit) { 201 }
        run_test!
      end
    end
  end

  path '/translations/{key}' do
    parameter name: :key, in: :path, schema: { type: :string }, required: true

    get 'Fetch all locale variants for a key' do
      tags 'Translations'
      security([{ 'BearerAuth' => [] }])
      produces 'application/json'

      response 200, 'returns every locale for the key' do
        schema type: :array, items: { '$ref' => '#/components/schemas/Translation' }

        let(:Authorization) { "Bearer #{plaintext_key}" }
        let!(:existing) do
          create(:translation, project: project, locale: target_locale, key: 'greeting',
                               source_text: 'Hello', status: 'completed', translated_text: 'Bonjour')
        end
        let(:key) { 'greeting' }

        run_test!
      end

      response 401, 'missing or invalid API key' do
        schema '$ref' => '#/components/schemas/ProblemDetails'
        let(:key) { 'greeting' }
        run_test!
      end

      response 404, 'no translations exist for this key' do
        schema '$ref' => '#/components/schemas/ProblemDetails'

        let(:Authorization) { "Bearer #{plaintext_key}" }
        let(:key) { 'does-not-exist' }
        run_test!
      end
    end
  end
end
