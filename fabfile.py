from fabric.api import *
from fabtools.vagrant import vagrant

""" Run tasks on a vagrant box with
     $ fab vagrant <task>
"""

@task
def build_custom_nginx():
    # put('tools/rebuld_nginx_with_pagespeed.sh')
    # run('rebuild_nginx_with_pagespeed.sh')
    get('/tmp/nginx*.deb', 'roles/nginx/files')
