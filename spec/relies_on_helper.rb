require 'support/relies_on_matchers'

RSpec.configure do |config|
  config.add_setting :relies_on

  config.before(:suite) do
    config.relies_on = build_relies_on
  end
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
  FileUtils.rm_r("related_repos") if Dir.exist?("related_repos")

  repo = repos[0]
  relies_on = build_relies_on_for_one_repo(repo[:repo_url], repo[:source_directory], repo[:relies_on_label], relies_on)

  FileUtils.mkdir("related_repos")
  FileUtils.cd("related_repos")
  repos[1..].each do |repo|
    system("git clone #{repo[:repo_url]}")
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

def relies_on_message(requirement)
  relies_on = RSpec.configuration.relies_on.fetch(requirement, [])
  if relies_on.any?
    "\nOther specs relying on requirement '#{requirement}':\n- #{relies_on.join("\n- ")}"
  else
    ""
  end
end

def read_requirement(full_path_file_name, line_number)
  file_name = "./#{full_path_file_name[`pwd`.length..]}"
  stdout, _, _ = Open3.capture3("grep", "-nr", "# @REQUIREMENT: ", file_name)
  lines = stdout.split("\n")
  lines.each do |line|
    matches = /#{file_name}:(\d+).+# @REQUIREMENT: (.+)/.match(line)
    if matches[1].to_i == line_number
      return matches[2]
    end
  end
  raise "requirement expected but not found at file #{file_name} line #{line_number}"
end
