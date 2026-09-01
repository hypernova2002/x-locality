# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backend::Emails::BrandedLayout do
  describe '#from_name' do
    it 'uses correspondence_name when set' do
      account = create(:account, name: 'Acme', correspondence_name: 'Acme Notifications')

      expect(described_class.from_name(account)).to eq('Acme Notifications')
    end

    it 'falls back to the account name when correspondence_name is blank' do
      account = create(:account, name: 'Acme', correspondence_name: nil)

      expect(described_class.from_name(account)).to eq('Acme')
    end

    it 'falls back to the account name when correspondence_name is an empty string' do
      account = create(:account, name: 'Acme', correspondence_name: '')

      expect(described_class.from_name(account)).to eq('Acme')
    end
  end

  describe '#logo_url' do
    it "uses the account's logo_url when set" do
      account = create(:account, logo_url: 'https://example.com/logo.png')

      expect(described_class.logo_url(account)).to eq('https://example.com/logo.png')
    end

    it 'falls back to the default x-locality logo when unset' do
      account = create(:account, logo_url: nil)

      expect(described_class.logo_url(account)).to eq(described_class.default_logo_url)
      expect(described_class.default_logo_url).to end_with('/xlocality-logo.svg')
    end
  end

  describe '#html' do
    it 'escapes HTML-unsafe characters in the title and embeds the logo/sender' do
      account = create(:account, name: 'Acme <3>', logo_url: 'https://example.com/logo.png')

      html = described_class.html(account: account, title: '<script>bad</script>', body_html: '<p>hi</p>')

      expect(html).to include('https://example.com/logo.png')
      expect(html).to include('&lt;script&gt;')
      expect(html).not_to include('<script>bad')
      expect(html).to include('<p>hi</p>')
    end
  end

  describe '#text' do
    it 'builds a plain-text version with the sender signature' do
      account = create(:account, name: 'Acme', correspondence_name: nil)

      text = described_class.text(account: account, title: 'Hello', body_text: 'Body text')

      expect(text).to eq("Hello\n\nBody text\n\n--\nSent by Acme via XLocality")
    end
  end
end
