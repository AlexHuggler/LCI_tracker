#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "date"

ROOT = File.expand_path("..", __dir__)

def read(path)
  File.read(File.join(ROOT, path))
end

def assert(condition, message)
  raise message unless condition
end

market_path = File.join(ROOT, "_data/market.yml")
market = File.exist?(market_path) ? YAML.load_file(market_path) : {}
languages = YAML.load_file(File.join(ROOT, "_data/languages.yml"))
competitors = YAML.load_file(File.join(ROOT, "_data/competitors.yml"))

assert(market.dig("app_store", "url") == "https://apps.apple.com/app/id6759516755", "use one neutral App Store URL")
assert(market.dig("app_store", "au_url") == "https://apps.apple.com/au/app/poolflow-pool-service-pro/id6759516755", "use the AU storefront only for AU acquisition pages")
assert(market.dig("pricing", "trial_days") == 30, "centralize the 30-day trial")
assert(market.dig("pricing", "monthly", "price") == "29.99", "centralize monthly pricing")
assert(languages.none? { |language| language.key?("app_store_url") }, "do not use country-specific App Store URLs")

competitors.each do |competitor|
  label = competitor.fetch("name")
  begin
    verified_at = Date.iso8601(competitor.fetch("verified_at"))
  rescue KeyError, Date::Error
    verified_at = nil
  end
  assert(verified_at, "#{label} comparison must record a valid ISO verification date")
  assert(verified_at <= Date.today, "#{label} comparison verification date cannot be in the future")
  sources = competitor.fetch("sources", [])
  assert(!sources.empty?, "#{label} comparison must cite at least one first-party source")
  sources.each do |source|
    assert(source["label"].to_s.strip != "", "#{label} source must have a label")
    assert(source["url"].to_s.start_with?("https://"), "#{label} source must use an HTTPS URL")
  end
  pricing = competitor.fetch("pricing")
  %w[card_value card_note summary].each do |field|
    assert(pricing[field].to_s.strip != "", "#{label} pricing must include #{field}")
  end
  assert(!pricing.key?("examples"), "#{label} must not use unsourced pool-count price examples")
end

%w[_includes/comparison-matrix.html _includes/comparison-feature-table.html].each do |path|
  template = read(path)
  assert(template.include?("Not verified"), "#{path} must distinguish unknown features from unavailable features")
  assert(template.include?("== false"), "#{path} must reserve the red X for explicitly false feature data")
  assert(!template.match?(/facts reviewed|reviewed \{\{|reviewed August/i), "#{path} must keep the access-date note beneath the hero")
end

comparison_layout = read("_layouts/competitor-comparison.html")
comparison_index = read("compare/index.html")
[comparison_layout, comparison_index].each do |template|
  assert(template.include?('href="#comparison-data-note"'), "comparison hero must link its asterisk to the data note")
  assert(template.include?('id="comparison-data-note"'), "comparison data note must sit in the hero")
  assert(template.include?("publicly available vendor materials accessed"), "comparison note must describe the source access date")
  assert(!template.match?(/facts reviewed|source-backed review/i), "comparison hero must not imply a formal fact review")
end
assert(!comparison_layout.include?("Competitor facts on this page were checked"), "vendor sources must use neutral access-date wording")
assert(!comparison_index.match?(/reviewed August 20, 2026/i), "comparison hub must not label the access date as a review date")

head = read("_includes/head.html")
default_layout = read("_layouts/default.html")
assert(default_layout.scan("{% seo %}").empty?, "one template must own canonical, social, and WebSite metadata")
assert(head.include?("<title>{{ document_title | escape }}</title>"), "the metadata owner must provide the document title")
assert(head.include?('meta name="description"'), "the metadata owner must provide a standard description")
assert(head.include?("name=\"robots\" content=\"noindex, nofollow\""), "404 pages must be noindex")
assert(head.include?("site.data.market.app_store.url"), "Organization schema must use the shared App Store URL")
assert(head.include?("https://poolflowapp.com/#publisher"), "use the stable legal publisher entity")
assert(head.include?("https://poolflowapp.com/#brand"), "use the stable PoolFlow brand entity")

hreflang = read("_includes/hreflang.html")
assert(hreflang.include?('hreflang="en-AU"'), "homepage cluster must include en-AU")

au_home = read("au/index.html")
assert(au_home.include?('lang: en-AU'), "AU homepage must declare en-AU")
assert(au_home.include?('market: au'), "AU homepage must select the AU market")
assert(au_home.include?("{% include homepage.html %}"), "US and AU homepages must share one homepage template")
assert(market.dig("australia", "app_store_url") == market.dig("app_store", "au_url"), "AU storefront must have one canonical value")
assert(market.dig("australia", "pricing", "monthly", "price") == "49.99", "AU monthly pricing must match the verified storefront")
assert(market.dig("australia", "pricing", "annual", "regular_price") == "299.99", "AU annual pricing must match the verified storefront")

landing = read("_layouts/landing-i18n.html")
assert(!landing.include?("default: \"Works without cell signal\""), "offline trust copy must not fall back to English")
assert(!landing.include?("lang_data.app_store_url"), "localized pages must use the neutral App Store URL")

%w[_includes/nav.html _includes/footer.html].each do |path|
  template = read(path)
  assert(!template.include?("l.app_store_url"), "#{path} must use the neutral App Store URL")
end

%w[privacy-policy.md terms-of-use.md].each do |path|
  body = read(path)
  assert(!body.match?(/^# /), "#{path} must not duplicate the layout H1")
  assert(!body.include?("LLC.."), "#{path} must not contain duplicated punctuation")
end

puts "source SEO checks passed"
