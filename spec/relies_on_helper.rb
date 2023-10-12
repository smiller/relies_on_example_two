require 'support/relies_on_matchers'

RSpec.configure do |config|
  config.add_setting :relies_on

  config.before(:suite) do
    config.relies_on = build_relies_on
  end

  config.include(ReliesOnMatchers)
end

def repos
  [
    # current repo
    {
      repo_url: "https://github.com/smiller/relies_on_example_two",
      source_directory: "./",
      relies_on_label: "# @RELIES_ON: "
    },
    # related repos
    {
      repo_url: "https://github.com/smiller/relies_on_example_two_related_repo",
      source_directory: "./relies_on_example_two_related_repo/",
      relies_on_label: "# @RELIES_ON: <repo:relies_on_example_two>:"
    }
  ]
end

def build_relies_on
  relies_on = Hash.new { |hash, key| hash[key] = [] }

  repo = repos[0]
  relies_on = build_relies_on_for_one_repo(repo[:repo_url], repo[:source_directory], repo[:relies_on_label], relies_on)

  unless ENV['REUSE_RELATED_REPOS'] == "true"
    FileUtils.rm_r("related_repos") if Dir.exist?("related_repos")
    FileUtils.mkdir("related_repos")
  end

  FileUtils.cd("related_repos")
  repos[1..].each do |repo|
    unless ENV['REUSE_RELATED_REPOS'] == "true"
      system("git clone #{repo[:repo_url]}")
    end

    relies_on = build_relies_on_for_one_repo(repo[:repo_url], repo[:source_directory], repo[:relies_on_label], relies_on)
  end
  FileUtils.cd("..")
  relies_on
end

def build_relies_on_for_one_repo(repo_url, source_directory, relies_on_label, relies_on)
  stdout, _, _ = Open3.capture3("grep", "-nr", relies_on_label, "#{source_directory}spec")
  lines = stdout.split("\n")
  lines.each do |line|
    file, key = line.split(/\:\s+#{relies_on_label}/)
    if file.include?("_spec.rb:")
      matches = /#{source_directory}([\w\/\.]+):(\d+)/.match(file)
      repo_link = "#{repo_url}/blob/main/#{matches[1]}#L#{matches[2]}"
      relies_on[key] << repo_link
    end
  end
  relies_on
end

def read_requirement(full_path_file_name, line_number)
puts "full_path_file_name=#{full_path_file_name}"
matches = /.+(\/spec\/.+)/.match(full_path_file_name)
puts "matches=#{matches.inspect}"
  file_name = ".#{matches[1]}"
  stdout, stderr, _ = Open3.capture3("grep", "-nr", "# @REQUIREMENT: ", file_name)
  puts "stdout=#{stdout}"
  puts "stderr=#{stderr}"
  lines = stdout.split("\n")
  lines.each do |line|
    # This is very weird.  This used to be
    # matches = /#{file_name}:(\d+).+# @REQUIREMENT: (.+)/.match(line)
    # which worked locally, but the line in the github actions version
    # started with the line number, not with "#{file_name}:", so it
    # worked locally but not on github actions.  This will presumably work
    # in both but I don't yet know why the github actions stdout is different.
    matches = /\D*(\d+).+# @REQUIREMENT: (.+)/.match(line)
    puts "matches=#{matches.inspect}"
    if matches[1].to_i == line_number
      return matches[2]
    end
  end
  raise "requirement expected but not found at file #{file_name} line #{line_number}"
end

def retrieve_relies_ons
  retrieve_labels("# @RELIES_ON: ", "./spec")
end

def match_requirements_to_relies_ons(relies_ons)
  matches = relies_ons.map { |key| [key, false] }.to_h
  matches.map { |relies_on, _| [relies_on, requirement_exists_for_relies_on?(relies_on)] }.to_h
end

def requirement_exists_for_relies_on?(relies_on)
  search_in = "./spec"
  if relies_on.start_with?("<repo:")
    matches = /<repo:(.+)> (.+)/.match(relies_on)
    repo = matches[1]
    relies_on = matches[2]
    search_in = "./related_repos/#{repo}/spec"
  end
  retrieve_labels("# @REQUIREMENT: ", search_in).include?(relies_on)
end

def retrieve_labels(label_marker, search_in)
  stdout, _, _ = Open3.capture3("grep", "-nr", label_marker, search_in)
  lines = stdout.split("\n").select { |l| l.include?("_spec.rb:") }
  lines.map do |line|
    _, label = line.split(/\:\s+#{label_marker}/)
    label
  end.uniq
end
