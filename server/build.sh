#!/bin/bash

# Get the absolute path of the directory containing build.sh and save it to wdir
wdir=$(dirname "$(realpath "$0")")

# Check if the correct number of arguments are provided
if [ "$#" -eq 0 ]; then
    echo "Error: No arguments provided. Exiting."
    echo "Usage: $0 [-s|-f] <project_directory_1> [<project_directory_2> ...] <output_directory>"
    exit 1
fi

# Check for flags
skip_install=false
force_install=false
while getopts ":fs" opt; do
    case ${opt} in
        f )
            force_install=true
            ;;
        s )
            skip_install=true
            ;;
        \? )
            echo "Usage: $0 [-s|-f] <project_directory_1> [<project_directory_2> ...] <output_directory>"
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# If both skip and force install flags are provided, display error message and exit
if [ "$skip_install" = true ] && [ "$force_install" = true ]; then
    echo "Error: Cannot use both -s and -f flags together."
    echo "Usage: $0 [-s|-f] <project_directory_1> [<project_directory_2> ...] <output_directory>"
    exit 1
fi

# If skip_install is false and force_install is false, ensure at least two arguments are provided
if [ "$skip_install" = false ] && [ "$force_install" = false ] && [ "$#" -lt 2 ]; then
    echo "Error: At least one project-to-build and an output directory should be provided.."
    echo "Usage: $0 [-s|-f] <project_directory_1> [<project_directory_2> ...] <output_directory>"
    exit 1
fi


if [ "$skip_install" = true ]; then
    echo "Skipping project installation."
else
    output_directory=${@: -1}

   if [ -d "$output_directory" ] && [ "$force_install" = false ]; then
      echo "Output directory already exists! Use -f flag to force installation."
      exit 0
   fi

   project_directories=("${@:1:$(($#-1))}")
    for arg in "${@:1:$(($#-1))}"; do
        project_directory=$(realpath "$arg")
        if [ ! -d "$project_directory" ]; then
           echo "Error: Project directory $project_directory does not exist"
           exit 1
        fi
        project_directories+=("$project_directory")
    done
    output_directory=$(realpath "$output_directory")

    # Ensure output directory is created if it doesn't exist
    if [ ! -d "$output_directory" ]; then
       echo "Creating output directory: $output_directory"
       mkdir -p "$output_directory"
    fi

    # Iterate over the project directories
    for project_directory in "${project_directories[@]}"; do
        # Navigate to the project directory
        cd "$project_directory" || exit
        # Build the project using Maven
        echo "Building project in $project_directory..."
        mvn clean install
        # Check if Maven build was successful
        if [ $? -eq 0 ]; then
           # Copy the produced JAR file to the output directory
           jar_file=$(find target -name '*.jar' -type f)
           if [ -n "$jar_file" ]; then
              echo "Copying $jar_file to $output_directory..."
              cp $jar_file $output_directory
           else
              echo "Error: No JAR file found in $project_directory/target"
              exit 1
           fi
       else
           echo "Error: Maven build failed for $project_directory"
           exit 1
       fi
   done
fi

########### Generating constants.py
# Navigate to the directory of the build.sh script
cd "$wdir" || exit

constants_gen_script=$(find . -type f -name "constants_gen.py" -print -quit)
constants_gen_script=$(realpath "job-dispatcher/src/utils/constants_gen.py")

echo "Generating constants.py using $constants_gen_script"

python_site_packages_path=$(python3 -c "import site; print(site.getsitepackages()[0])")
root_dir=$(realpath "./job-dispatcher/src")
neo4j_plugin_path="/var/lib/neo4j/plugins/"
log_file_path="/tmp/" 

if [ -z "$output_directory" ]; then
	output_directory=$(realpath "./artifacts")
	echo "Jars Directory is empty. Setting default value: $output_directory"
	if [ ! -d $output_directory ]; then
	   echo "Creating Jars Directory.."
	   mkdir "$output_directory"
	fi
fi 

python3 $constants_gen_script $python_site_packages_path $root_dir $output_directory $neo4j_plugin_path $log_file_path

