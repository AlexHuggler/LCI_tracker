#!/usr/bin/env ruby
# frozen_string_literal: true

require "nokogiri"
require "json"
require "yaml"

ROOT = File.expand_path("..", __dir__)
SITE = File.join(ROOT, "_site")
AU_STORE_HOST_PATH = "apps.apple.com/au/"

def assert(condition, message)
  raise message unless condition
end

def page(path)
  file = File.join(SITE, path, "index.html")
  assert(File.exist?(file), "missing built page /#{path}/")
  Nokogiri::HTML(File.read(file))
end

market = YAML.load_file(File.join(ROOT, "_data/market.yml"))
au = market.fetch("australia")
assert(au.dig("pricing", "monthly", "price") == "49.99", "AU monthly price must be A$49.99")
assert(au.dig("pricing", "annual", "regular_price") == "299.99", "AU annual price must be A$299.99")
assert(au.dig("pricing", "trial_days") == 30, "AU introductory period must be 30 days")

home = page("au")
home_text = home.text.gsub(/\s+/, " ")
us_home = page("")
us_home_text = us_home.text.gsub(/\s+/, " ")
assert(home.at_css("html")&.[]("lang") == "en-AU", "AU homepage must render lang=en-AU")
assert(home.at_css("#hero"), "AU homepage must use the full homepage hero")
assert(home.at_css("#features"), "AU homepage must use the full homepage feature stack")
assert(home.at_css("#pricing"), "AU homepage must use the full homepage pricing section")
assert(home_text.include?("A$49.99"), "AU homepage must show the verified monthly price")
assert(home_text.include?("A$299.99"), "AU homepage must show the verified annual price")
assert(home_text.include?("30-day"), "AU homepage must show the verified introductory period")
assert(!home_text.include?("$29.99"), "AU homepage must not leak the US monthly price")
assert(!home_text.include?("$199.99"), "AU homepage must not leak the US annual price")
assert(!home_text.include?("2 months free"), "AU annual copy must match the verified AU price ratio")
assert(home_text.include?("approximately 30-day introductory period"), "AU trial language must remain qualified")
assert(!home_text.include?("There is no scenario where you lose"), "AU homepage must not contain an unsupported outcome guarantee")
assert(us_home_text.include?("$29.99"), "US homepage must preserve the US monthly price")
assert(us_home_text.include?("$199.99"), "US homepage must preserve the US annual price")
assert(!us_home_text.include?("A$49.99"), "US homepage must not leak the AU monthly price")
us_section_ids = us_home.css("section[id]").map { |section| section["id"] }
au_section_ids = home.css("section[id]").map { |section| section["id"] }
assert((us_section_ids - au_section_ids).empty?, "AU homepage must preserve every identified US homepage section")

apple_links = home.css('a[href*="apps.apple.com"]')
assert(!apple_links.empty?, "AU homepage must include App Store links")
assert(apple_links.all? { |link| link["href"].include?(AU_STORE_HOST_PATH) }, "every AU homepage App Store link must use the AU storefront")

required_home_links = ["/au/", "/au/#features", "/au/#pricing", "/au/tools/", "/au/compare/", "/au/support/"]
hrefs = home.css("a[href]").map { |link| link["href"] }
required_home_links.each do |href|
  assert(hrefs.include?(href), "AU homepage is missing market-preserving link #{href}")
end

tool_paths = %w[
  au/tools
  au/lsi-calculator
  au/chemical-dosing-calculator
  au/pool-volume-calculator
  au/salt-calculator
  au/free-chlorine-calculator
  au/pump-run-time-calculator
]

tool_paths.each do |path|
  document = page(path)
  assert(document.at_css("html")&.[]("lang") == "en-AU", "/#{path}/ must render lang=en-AU")
  links = document.css('a[href*="apps.apple.com"]')
  assert(!links.empty?, "/#{path}/ must include an App Store link")
  assert(links.all? { |link| link["href"].include?(AU_STORE_HOST_PATH) }, "/#{path}/ must keep App Store links in Australia")
  assert(document.css('a[href="/au/"]').any?, "/#{path}/ must link home to /au/")
end

support = page("au/support")
assert(support.at_css("html")&.[]("lang") == "en-AU", "AU support must render lang=en-AU")
assert(support.css('a[href="/au/"]').any?, "AU support must link home to /au/")

{
  "au/compare" => ["en-US", "https://poolflowapp.com/compare/"],
  "au/support" => ["en-US", "https://poolflowapp.com/support/"]
}.each do |path, (language, target)|
  document = page(path)
  alternate = document.at_css(%(link[rel="alternate"][hreflang="#{language}"]))
  assert(alternate&.[]("href") == target, "/#{path}/ must declare #{language} alternate #{target}")
end

dosing = page("au/chemical-dosing-calculator")
assert(dosing.text.include?("Cost estimates are omitted"), "AU dosing must explain why generic currency estimates are omitted")
assert(!dosing.text.include?("$0.00"), "AU dosing must not render a generic US-dollar estimate")

au_pages = Dir.glob(File.join(SITE, "au", "**", "index.html"))
us_commercial_path = %r{\A/(?:tools|lsi-calculator|chemical-dosing-calculator|pool-volume-calculator|salt-calculator|free-chlorine-calculator|pump-run-time-calculator|compare|support)(?:/|#|\z)}
au_pages.each do |file|
  document = Nokogiri::HTML(File.read(file))
  canonical = document.css('link[rel="canonical"]')
  assert(canonical.length == 1, "#{file.delete_prefix(SITE)} must have exactly one canonical")
  document.css('script[type="application/ld+json"]').each_with_index do |node, index|
    JSON.parse(node.text)
  rescue JSON::ParserError => error
    raise "#{file.delete_prefix(SITE)} has invalid JSON-LD block #{index + 1}: #{error.message}"
  end
  leaked_link = document.css('a[href]:not([data-market-switch="us"])').map { |link| link["href"] }.find { |href| href.match?(us_commercial_path) }
  assert(leaked_link.nil?, "#{file.delete_prefix(SITE)} leaks an AU visitor to #{leaked_link}")
end

%w[
  au/lsi-calculator
  au/chemical-dosing-calculator
  au/pool-volume-calculator
  au/salt-calculator
  au/free-chlorine-calculator
  au/pump-run-time-calculator
].each do |path|
  source = File.read(File.join(SITE, path, "index.html"))
  assert(source.include?('"priceCurrency": "AUD"'), "/#{path}/ schema must use AUD")
  assert(source.include?('"publisher": { "@id": "https://poolflowapp.com/#publisher" }'), "/#{path}/ schema must use the canonical publisher entity")
end

assert(page("au/chemical-dosing-calculator").text.include?("liquid doses in mL/L"), "AU dosing copy must be metric-first")
assert(page("au/salt-calculator").text.include?("kilograms of salt"), "AU salt copy must be metric-first")
assert(page("au/pump-run-time-calculator").text.include?("litres per minute"), "AU pump copy must be metric-first")
assert(page("au/pool-volume-calculator").text.include?("dimensions in metres"), "AU volume copy must be metric-first")

sitemap = Nokogiri::XML(File.read(File.join(SITE, "sitemap.xml")))
sitemap.remove_namespaces!
sitemap_urls = sitemap.css("loc").map(&:text)
(tool_paths + ["au/support"]).each do |path|
  expected = "https://poolflowapp.com/#{path}/"
  assert(sitemap_urls.include?(expected), "sitemap is missing #{expected}")
end

puts "AU market checks passed"
