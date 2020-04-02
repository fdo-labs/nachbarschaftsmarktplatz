#   Copyright (c) 2012-2017, Fairmondo eG.  This file is
#   licensed under the GNU Affero General Public License version 3 or later.
#   See the COPYRIGHT file for details.

set :stage, :staging
set :deploy_to, '/home/deploy/nmp-stage'

server '78.47.131.16', user: 'deploy', roles: %w{web app db sidekiq console}

set :branch, ENV['BRANCH_NAME'] || 'develop'
