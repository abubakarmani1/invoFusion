#!/bin/bash

# Configuration variables
START_DATE="2024-10-02"
END_DATE="2024-19-21"
MIN_COMMITS_PER_DAY=5    # Minimum commits
MAX_COMMITS_PER_DAY=25   # Maximum commits
GITHUB_EMAIL="abubakar.mani1@gmail.com"
GITHUB_NAME="Abubakar Saddique"
REPO_URL="https://github.com/abubakarmani1/invoFusion.git"

# Convert dates to seconds since epoch for comparison
start_seconds=$(date -j -f "%Y-%m-%d" "$START_DATE" "+%s")
end_seconds=$(date -j -f "%Y-%m-%d" "$END_DATE" "+%s")
days_between=$((($end_seconds - $start_seconds) / 86400 + 1))

# Configure Git globally
git config --global user.email "$GITHUB_EMAIL"
git config --global user.name "$GITHUB_NAME"

# Configure local repository
git config user.email "$GITHUB_EMAIL"
git config user.name "$GITHUB_NAME"

# Set environment variables for commits
export GIT_AUTHOR_EMAIL="$GITHUB_EMAIL"
export GIT_AUTHOR_NAME="$GITHUB_NAME"
export GIT_COMMITTER_EMAIL="$GITHUB_EMAIL"
export GIT_COMMITTER_NAME="$GITHUB_NAME"

# Function to generate random time between 9 AM and 5 PM
generate_random_time() {
    hour=$((RANDOM % 9 + 9))    # Random hour between 9-17 (9 AM - 5 PM)
    minute=$((RANDOM % 60))     # Random minute between 0-59
    second=$((RANDOM % 60))     # Random second between 0-59
    printf "%02d:%02d:%02d" $hour $minute $second
}

# Function to generate random commits for a day
generate_daily_commits() {
    # Generate a random pattern for the day
    local pattern=$((RANDOM % 4))  # 0-3 for different patterns
    
    case $pattern in
        0) # Light day
            echo $((RANDOM % 5 + MIN_COMMITS_PER_DAY))  # 5-10 commits
            ;;
        1) # Medium day
            echo $((RANDOM % 10 + 10))  # 10-20 commits
            ;;
        2) # Heavy day
            echo $((RANDOM % 10 + 15))  # 15-25 commits
            ;;
        3) # Variable day
            echo $((RANDOM % (MAX_COMMITS_PER_DAY - MIN_COMMITS_PER_DAY) + MIN_COMMITS_PER_DAY))
            ;;
    esac
}

# Check if commits already exist for the date range
COMMIT_CHECK=$(git log --since="$START_DATE" --until="$END_DATE" --oneline | wc -l)
if [ $COMMIT_CHECK -gt 0 ]; then
    echo "Commits already exist for the specified date range. Skipping to prevent duplicates."
    exit 1
fi

# Remove existing remote if it exists
git remote remove origin 2>/dev/null

# Initialize new repository
git init
echo "Starting contributions log" > contributions.txt
git add contributions.txt

# Set initial commit with random time
INITIAL_TIME=$(generate_random_time)
export GIT_AUTHOR_DATE="${START_DATE}T$INITIAL_TIME"
export GIT_COMMITTER_DATE="${START_DATE}T$INITIAL_TIME"

git commit -m "Initial commit"

# Initialize total commits counter
total_commits=0

# Loop through each day in the date range
current_date=$start_seconds
for ((day=1; day<=days_between; day++)); do
    # Format current date
    formatted_date=$(date -r $current_date "+%Y-%m-%d")
    formatted_day=$(date -r $current_date "+%d")
    
    # Random number of commits for this day
    commits_today=$(generate_daily_commits)
    
    echo "Creating $commits_today commits for $formatted_date"
    
    for ((commit=1; commit<=commits_today; commit++)); do
        # Generate unique content for each commit
        timestamp=$(date +%s)
        echo "Update for $formatted_date - Commit $commit (Timestamp: $timestamp)" >> contributions.txt
        git add contributions.txt
        
        # Set random time for each commit
        random_time=$(generate_random_time)
        export GIT_AUTHOR_DATE="${formatted_date}T${random_time}"
        export GIT_COMMITTER_DATE="${formatted_date}T${random_time}"
        
        git commit -m "Update for $formatted_date (#$commit)"
        
        # Increment total commits counter
        total_commits=$((total_commits + 1))
        
        # Add random sleep to make it more natural
        sleep 0.$((RANDOM % 5))
    done
    
    # Move to next day
    current_date=$((current_date + 86400))
done

# Better handling of remote origin
if git remote | grep -q 'origin'; then
    git remote set-url origin "$REPO_URL"
else
    git remote add origin "$REPO_URL"
fi

# Attempt to push, with error handling
if git push -f origin main; then
    echo "Successfully pushed commits to GitHub"
    echo "Total commits created: $total_commits"
    echo "Date range: $START_DATE to $END_DATE"
else
    echo "Failed to push commits to GitHub"
    exit 1
fi