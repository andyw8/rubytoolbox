# frozen_string_literal: true

class ProjectUpdateJob < ApplicationJob
  # The react-source gem references the upstream JS react
  # repo, which has an extremely large audience on github.
  # However it doesn't seem to have any affiliation with react
  # itself. Since react's github popularity metrics (stars, forks)
  # are much higher than the most popular ruby repo (at the time of
  # writing ;) this skews popularity scores, since the max stars and
  # forks are considered for the overall popularity scoring.
  # Hence, this gem is being prevented from linking against
  # it's referenced github repo.
  REPO_LINK_BLACKLIST = %w[
    react-source
    react-source-fb-cloned
    ruby-watchman
  ].freeze

  #
  # Some gems reference an upstream code generator or similar tool
  # that are technically unrelated but have a lot of github stars etc,
  # leading to inflated popularity scores.
  #
  # This blacklist prevents references to those github repos.
  #
  TEMPLATE_REPO_BLACKLIST = %w[
    swagger-api/swagger-codegen
  ].freeze

  def perform(permalink)
    Project.find_or_initialize_by(permalink:).tap do |project|
      project.rubygem = Rubygem.find_by(name: permalink)
      project.github_repo_path = detect_repo_path(project)
      project.description = project.rubygem_description || project.github_repo_description
      project.save!
      ProjectScoreJob.perform_async permalink
      ProjectSearchIndexJob.perform_async permalink
      enqueue_github_repo_sync project.github_repo_path
    end
  end

  private

  def detect_repo_path(project)
    if project.github_only?
      project.permalink
    else
      return unless project.rubygem
      return if REPO_LINK_BLACKLIST.include? project.rubygem_name

      name = Github.detect_repo_name project.rubygem.homepage_url,
                                     project.rubygem.source_code_url,
                                     project.rubygem.bug_tracker_url
      name unless TEMPLATE_REPO_BLACKLIST.include? name
    end
  end

  def enqueue_github_repo_sync(path)
    return if path.nil? || GithubRepo.find_by(path:)

    GithubRepoUpdateJob.perform_async path
  end
end
