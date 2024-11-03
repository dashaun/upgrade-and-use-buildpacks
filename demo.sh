#!/usr/bin/env bash

TEMP_DIR="upgrade-example"
JAVA_8="8.0.432-librca"
JAVA_23="24.1.r23-nik"
JAR_NAME="hello-spring-0.0.1-SNAPSHOT.jar"

# Function definitions

check_dependencies() {
    local tools=("vendir" "http")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "$tool not found. Please install $tool first."
            exit 1
        fi
    done
}

talking_point() {
    wait
    clear
}

init_sdkman() {
    local sdkman_init="${SDKMAN_DIR:-$HOME/.sdkman}/bin/sdkman-init.sh"
    if [[ -f "$sdkman_init" ]]; then
        source "$sdkman_init"
    else
        echo "SDKMAN not found. Please install SDKMAN first."
        exit 1
    fi
    sdk env install
}

init() {
    rm -rf "$TEMP_DIR"
    mkdir "$TEMP_DIR"
    cd "$TEMP_DIR" || exit
    clear
}

use_java() {
    local version=$1
    displayMessage "Use Java $version"
    sdk use java "$version"
    java -version
}

clone_app() {
    displayMessage "Clone a Spring Boot 2.6.0 application"
    git clone https://github.com/dashaun/hello-spring-boot-2-6.git ./
}

java_dash_jar() {
    displayMessage "Start the Spring Boot application (with java -jar)"
    ./mvnw -q clean package -DskipTests
    java -jar ./target/$JAR_NAME 2>&1 | tee "$1" &
}

java_stop() {
    displayMessage "Stop the Spring Boot application"
    local npid=$(pgrep java)
    pei "kill -9 $npid"
}

remove_extracted() {
    rm -rf application
}

aot_processing() {
  displayMessage "Package using AOT Processing"
  ./mvnw -q -Pnative clean package -DskipTests
  displayMessage "Done"
}

java_dash_jar_aot_enabled() {
  displayMessage "Start the Spring Boot application with AOT enabled"
  java -Dspring.aot.enabled=true -jar ./target/$JAR_NAME 2>&1 | tee "$1" &
}

java_dash_jar_extract() {
    displayMessage "Extract the Spring Boot application for efficiency (java -Djarmode=tools)"
    displayMessage "Buildpacks have been doing this, automatically, since the beginning"
    java -Djarmode=tools -jar ./target/$JAR_NAME extract --destination application
    displayMessage "Done"
}

java_dash_jar_exploded() {
    displayMessage "Start the extracted Spring Boot application, (java -jar [exploded])"
    java -jar ./application/$JAR_NAME 2>&1 | tee "$1" &
}

create_cds_archive() {
  displayMessage "Create a Class Data Sharing (CDS) archive"
  java -XX:ArchiveClassesAtExit=application.jsa -Dspring.context.exit=onRefresh -jar application/$JAR_NAME | grep -v "[warning][cds]"
  displayMessage "Done"
}

java_dash_jar_cds() {
  displayMessage "Start the Spring Boot application with CDS archive, Wait For It...."
  java -XX:SharedArchiveFile=application.jsa -jar application/$JAR_NAME 2>&1 | tee "$1" &
}

java_dash_jar_aot_cds() {
  displayMessage "Start the Spring Boot application with CDS archive, Wait For It...."
  java -Dspring.aot.enabled=true -XX:SharedArchiveFile=application.jsa -jar application/$JAR_NAME 2>&1 | tee "$1" &
}

validate_app() {
    displayMessage "Check application health"
    while ! http :8080/actuator/health 2>/dev/null; do sleep 1; done
}

show_memory_usage() {
    displayMessage "Check how much memory the application is using."
    local pid=$1
    local log_file=$2
    local rss
    rss=$(ps -o rss= "$pid" | tail -n1)
    local mem_usage
    mem_usage=$(bc <<< "scale=1; ${rss}/1024")
    echo "The process was using ${mem_usage} megabytes"
    echo "${mem_usage}" >> "$log_file"
}

rewrite_application() {
    displayMessage "Upgrade to Spring Boot 3.3 using OpenRewrite"
    ./mvnw -U org.openrewrite.maven:rewrite-maven-plugin:run \
        -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-spring:LATEST \
        -Drewrite.activeRecipes=org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_3 | grep "WARNING"
}

build_oci() {
    displayMessage "Build OCI images"
    docker pull dashaun/builder:tiny && docker tag dashaun/builder:tiny paketobuildpacks/builder:tiny && docker tag dashaun/builder:tiny paketobuildpacks/builder:base
    ./mvnw clean spring-boot:build-image -Dspring-boot.build-image.imageName=demo:0.0.1-JVM -Dspring-boot.build-image.createdDate=now
    ./mvnw clean -Pnative spring-boot:build-image -Dspring-boot.build-image.imageName=demo:0.0.1-Native -Dspring-boot.build-image.createdDate=now
}

displayMessage() {
    echo "#### $1"
    echo
}

startup_time() {
    sed -nE 's/.* in ([0-9]+\.[0-9]+) seconds.*/\1/p' < "$1"
}

stats_so_far_table() {
    displayMessage "Comparison of memory usage and startup times"
    echo

    printf "%-35s %-25s %-15s %s\n" "Configuration" "Startup Time (seconds)" "(MB) Used" "(MB) Savings"
    echo "--------------------------------------------------------------------------------------------"

    local mem1 start1 mem2 start2 perc2 percstart2 mem3 start3 perc3 percstart3 mem4 start4 perc4 percstart4 mem5 start5 perc5 percstart5 mem6 start6 perc6 percstart6 mem7 start7 perc7 percstart7
    mem1=$(cat java8with2.6.log2)
    start1=$(startup_time 'java8with2.6.log')
    printf "%-35s %-25s %-15s %s\n" "Spring Boot 2.6 with Java 8" "$start1" "$mem1" "-"

    mem2=$(cat java23with3.3.log2)
    perc2=$(bc <<< "scale=2; 100 - ${mem2}/${mem1}*100")
    start2=$(startup_time 'java23with3.3.log')
    percstart2=$(bc <<< "scale=2; 100 - ${start2}/${start1}*100")
    printf "%-35s %-25s %-15s %s \n" "Spring Boot 3.3 with Java 23" "$start2 ($percstart2% faster)" "$mem2" "$perc2%"

    mem3=$(cat exploded.log2)
    perc3=$(bc <<< "scale=2; 100 - ${mem3}/${mem1}*100")
    start3=$(startup_time 'exploded.log')
    percstart3=$(bc <<< "scale=2; 100 - ${start3}/${start1}*100")
    printf "%-35s %-25s %-15s %s \n" "Spring Boot 3.3 extracted" "$start3 ($percstart3% faster)" "$mem3" "$perc3%"

    mem5=$(cat aot.log2)
    perc5=$(bc <<< "scale=2; 100 - ${mem5}/${mem1}*100")
    start5=$(startup_time 'aot.log')
    percstart5=$(bc <<< "scale=2; 100 - ${start5}/${start1}*100")
    printf "%-35s %-25s %-15s %s \n" "Spring Boot 3.3 with AOT processing" "$start5 ($percstart5% faster)" "$mem5" "$perc5%"

    mem4=$(cat cds.log2)
    perc4=$(bc <<< "scale=2; 100 - ${mem4}/${mem1}*100")
    start4=$(startup_time 'cds.log')
    percstart4=$(bc <<< "scale=2; 100 - ${start4}/${start1}*100")
    printf "%-35s %-25s %-15s %s \n" "Spring Boot 3.3 with CDS" "$start4 ($percstart4% faster)" "$mem4" "$perc4%"

    mem6=$(cat aotcds.log2)
    perc6=$(bc <<< "scale=2; 100 - ${mem6}/${mem1}*100")
    start6=$(startup_time 'aotcds.log')
    percstart6=$(bc <<< "scale=2; 100 - ${start6}/${start1}*100")
    printf "%-35s %-25s %-15s %s \n" "Spring Boot 3.3 with AOT+CDS" "$start6 ($percstart6% faster)" "$mem6" "$perc6%"

    # Spring Boot 3.3 with AOT processing, native image
    #STARTUP3=$(grep -o 'Started HelloSpringApplication in .*' < nativeWith3.3.log)
    mem7=$(cat nativeWith3.3.log2)
    perc7=$(bc <<< "scale=2; 100 - ${mem7}/${mem1}*100")
    start7=$(startup_time 'nativeWith3.3.log')
    percstart7=$(bc <<< "scale=2; 100 - ${start7}/${start1}*100")
    printf "%-35s %-25s %-15s %s \n" "Spring Boot 3.3 with AOT, native" "$start7 ($percstart7% faster)" "$mem7" "$perc7%"

    echo "--------------------------------------------------------------------------------------------"
}

# Build a native image of the application
function buildNative {
  displayMessage "Build a native image with AOT"
  pei "./mvnw -Pnative native:compile"
}

# Start the native image
function startNative {
  displayMessage "Start the native image"
  pei "./target/hello-spring 2>&1 | tee nativeWith3.3.log &"
}

# Stop the native image
function stopNative {
  displayMessage "Stop the native image"
  local npid=$(pgrep hello-spring)
  pei "kill -9 $npid"
}

image_stats() {
    docker images | grep demo
}

# Main execution flow

main() {
    if [[ $# -eq 1 && "$1" =~ ^(-h|--help)$ ]]; then
        usage
        exit 0
    fi

    check_dependencies
    vendir sync
    source ./vendir/demo-magic/demo-magic.sh
    export TYPE_SPEED=100
    export DEMO_PROMPT="${GREEN}➜ ${CYAN}\W ${COLOR_RESET}"
    export PROMPT_TIMEOUT=5

    init_sdkman
    init
    use_java $JAVA_8
    talking_point
    clone_app
    talking_point
    java_dash_jar java8with2.6.log
    talking_point
    validate_app
    talking_point
    show_memory_usage "$(pgrep java | cut -d ' ' -f 1)" java8with2.6.log2
    talking_point
    java_stop
    talking_point
    rewrite_application
    talking_point
    use_java $JAVA_23
    talking_point
    java_dash_jar java23with3.3.log
    talking_point
    validate_app
    talking_point
    show_memory_usage "$(pgrep java | cut -d ' ' -f 1)" java23with3.3.log2
    talking_point
    java_stop
    talking_point
    java_dash_jar_extract
    talking_point
    java_dash_jar_exploded exploded.log
    talking_point
    validate_app
    talking_point
    show_memory_usage "$(pgrep java)" exploded.log2
    talking_point
    java_stop
    talking_point
    aot_processing
    talking_point
    java_dash_jar_aot_enabled aot.log
    talking_point
    validate_app
    talking_point
    show_memory_usage "$(pgrep java | cut -d ' ' -f 1)" aot.log2
    talking_point
    java_stop
    talking_point
    create_cds_archive
    talking_point
    java_dash_jar_cds cds.log
    talking_point
    validate_app
    talking_point
    show_memory_usage "$(pgrep java)" cds.log2
    talking_point
    java_stop
    talking_point
    remove_extracted
    aot_processing
    talking_point
    java_dash_jar_extract
    talking_point
    create_cds_archive
    java_dash_jar_aot_cds aotcds.log
    talking_point
    validate_app
    talking_point
    show_memory_usage "$(pgrep java)" aotcds.log2
    talking_point
    java_stop
    talking_point
    buildNative
    talking_point
    startNative
    talking_point
    validate_app
    talking_point
    show_memory_usage "$(pgrep hello-spring)" nativeWith3.3.log2
    talking_point
    stopNative
    talking_point
    stats_so_far_table
}

main
