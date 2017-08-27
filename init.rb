require 'redmine'
require_dependency 'hooks' 
require_dependency 'query_column'

# patch issue_query to allow columns for votes
issue_query = (IssueQuery rescue Query)
issue_query.add_available_column(VOI_QueryColumn.new(:sum_votes_up, :sortable => '(SELECT abs(sum(vote_val)) FROM vote_on_issues WHERE vote_val > 0 AND issue_id=issues.id )'))
issue_query.add_available_column(VOI_QueryColumn.new(:sum_votes_dn, :sortable => '(SELECT abs(sum(vote_val)) FROM vote_on_issues WHERE vote_val < 0 AND issue_id=issues.id )'))
Issue.send(:include, VoteOnIssues::Patches::QueryPatch)

ActionDispatch::Callbacks.to_prepare do
  IssuesController.class_eval do
    helper :vote_on_issues
  end
end

Redmine::Plugin.register :vote_on_issues do
  name 'Vote On Issues'
  description 'This plugin allows to up- and down-vote issues.'
  version '1.0.2'
  url 'https://github.com/ojde/redmine-vote_on_issues-plugin'
  author 'Ole Jungclaussen'
  author_url 'https://jungclaussen.com'
  
  requires_redmine  :version_or_higher => '3.3.2'
  
  project_module :vote_on_issues do
    permission :cast_votes, {vote_on_issues: [:create, :destroy] }, :require => :loggedin
    permission :view_votes, {vote_on_issues: [:show]}, :require => :loggedin
    permission :view_voters, {vote_on_issues: :view_voters}, :require => :loggedin
  end

  # permission for menu
  # permission :vote_on_issues, { :vote_on_issues => [:index] }, :public => true
  # menu :project_menu,
  #   :vote_on_issues, 
  #   { :controller => 'vote_on_issues', :action => 'index' },
  #   :caption => :menu_title,
  #   :after => :issues,
  #   :param => :project_id,
  #   :if =>  Proc.new {
  #     User.current.allowed_to?(:view_votes, nil, :global => true)
  #   }
  
end

class VoteOnIssuesListener < Redmine::Hook::ViewListener
  render_on :view_layouts_base_html_head, :inline =>  <<-END
      <%= stylesheet_link_tag 'view_issues_vote', :plugin => 'vote_on_issues' %>
      <%= javascript_include_tag 'view_issues_vote', :plugin => 'vote_on_issues' %>
    END
end
