
block_ci_url := "https://block-ci.fly.dev"
current_commit := `git rev-parse HEAD`
commit_status_url := block_ci_url / current_commit / "status"
commit_tests_url := block_ci_url / current_commit / "test?tests_ok=true"
commit_build_url := block_ci_url / current_commit / "build?build_ok=true"
commit_deploy_url := block_ci_url / current_commit / "deploy?deploy_ok=true"



test:
    #!/bin/bash
    test_stat=`curl -s {{ commit_status_url }} | jq .tests_ok`
    if [ "$test_stat" == "true" ]; then
        echo "Tests already passed for this commit"
        exit 0
    else
        pytest
    fi
    curl -s -X POST {{ commit_tests_url }}

build:
    #!/bin/bash
    build_stat=`curl -s {{ commit_status_url }} | jq .build_ok`
    if [ "$build_stat" == "true" ]; then
        echo "Build already passed for this commit"
        exit 0
    else
        test_stat=`curl -s {{ commit_status_url }} | jq .tests_ok`
        if [ "$test_stat" != "true" ]; then
            echo "Tests failed for this commit, run tests first"
            exit 1
        fi
        echo "Building the project"
    fi
    curl -s -X POST {{ commit_build_url }}

deploy:
    #!/bin/bash
    deploy_stat=`curl -s {{ commit_status_url }} | jq .deploy_ok`
    if [ "$deploy_stat" == "true" ]; then
        echo "Deploy already passed for this commit"
        exit 0
    else
        echo "Deploying the project"
    fi
    curl -s -X POST {{ commit_deploy_url }}
