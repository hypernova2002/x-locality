# frozen_string_literal: true

module Backend
  # Seeded into every new project as system: true locales - not exhaustive
  # ISO 639-1, just a practical starter set. More can be added later without
  # a migration since this only drives seeding, not a DB enum.
  SystemLocales = {
    'en' => 'English', 'fr' => 'French', 'de' => 'German', 'es' => 'Spanish',
    'it' => 'Italian', 'pt' => 'Portuguese', 'nl' => 'Dutch', 'pl' => 'Polish',
    'sv' => 'Swedish', 'da' => 'Danish', 'fi' => 'Finnish', 'nb' => 'Norwegian',
    'ja' => 'Japanese', 'zh' => 'Chinese', 'ko' => 'Korean', 'hi' => 'Hindi',
    'ar' => 'Arabic', 'ru' => 'Russian', 'tr' => 'Turkish', 'vi' => 'Vietnamese'
  }.freeze
end
