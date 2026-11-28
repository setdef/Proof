# frozen_string_literal: true

require "rubocop"

# RuboCop takes the topmost Gemfile above the working directory as the project root, so a checkout below another
# folder with a Gemfile is checked against that folder (rubocop/rubocop#11011). RuboCop reads no option, environment
# variable, or setting for the root, and .rubocop.yml loads this file with `require:`.
RuboCop::ConfigFinder.project_root = File.expand_path("..", __dir__)
