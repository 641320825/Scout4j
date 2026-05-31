#!/usr/bin/env bash
set -euo pipefail

root="${1:-.}"
cd "$root"

has() { command -v "$1" >/dev/null 2>&1; }
search() {
  local pattern="$1"
  local max_count="${2:-80}"
  if has rg; then
    rg -n -m "$max_count" "$pattern" . || true
  else
    grep -RInE "$pattern" . | head -"$max_count" || true
  fi
}

echo "== Local agent guidance =="
find . -maxdepth 3 \( -name AGENTS.md -o -name CLAUDE.md -o -name CONTRIBUTING.md -o -name README.md \) | sort

echo
echo "== Git status =="
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git status --short || true
else
  echo "not a git repository"
fi

echo
echo "== Build files =="
find . -maxdepth 4 \( -name pom.xml -o -name 'build.gradle*' -o -name settings.gradle -o -name settings.gradle.kts \) | sort

if [ -x ./mvnw ]; then
  echo
  echo "== Maven wrapper =="
  echo "./mvnw"
elif has mvn; then
  echo
  echo "== Maven command =="
  echo "mvn"
fi

if [ -x ./gradlew ]; then
  echo
  echo "== Gradle wrapper =="
  echo "./gradlew"
elif has gradle; then
  echo
  echo "== Gradle command =="
  echo "gradle"
fi

echo
echo "== Maven modules (artifactId near pom.xml) =="
find . -maxdepth 4 -name pom.xml | sort | while read -r pom; do
  dir=${pom%/pom.xml}
  artifact=$(python3 - "$pom" <<'PY' 2>/dev/null || true
import re, sys
text=open(sys.argv[1], encoding='utf-8', errors='ignore').read()
m=re.search(r'<artifactId>\s*([^<]+?)\s*</artifactId>', text)
print(m.group(1) if m else '')
PY
)
  printf '%s%s\n' "$dir" "${artifact:+  ($artifact)}"
done

echo
echo "== Gradle project hints =="
find . -maxdepth 3 \( -name settings.gradle -o -name settings.gradle.kts \) -print -exec sed -n '1,120p' {} \; 2>/dev/null || true

echo
echo "== Common Java entry annotations =="
search "@RestController|@Controller|@RequestMapping|@GetMapping|@PostMapping|@Path\\(|@KafkaListener|@RabbitListener|@JmsListener|@Scheduled|@EventListener"

echo
echo "== Persistence / mapping hints =="
search "@Entity|JpaRepository|CrudRepository|@Mapper|Mapper<|Dao|Repository|JdbcTemplate|DSLContext|MapStruct|Converter|Assembler|Translator"

echo
echo "== Security / tenancy hints =="
search "permission|authorize|authorization|authz|tenant|orgId|userId|data-scope|dataScope|softDelete|deleted|isDeleted"

echo
echo "== Java package roots =="
find . -path '*/src/main/java/*' -name '*.java' | sed 's#^./##' | head -200 | sed 's#/src/main/java/.*#/src/main/java#' | sort -u | head -80

echo
echo "== Tests =="
find . -path '*src/test*' \( -name '*Test.java' -o -name '*Tests.java' -o -name '*Spec.groovy' \) | sort | head -200

echo
echo "== Suggested next commands =="
if [ -x ./mvnw ]; then
  echo "./mvnw -pl <module> test -Dtest=XxxTest"
  echo "./mvnw -pl <module> -am test"
elif has mvn; then
  echo "mvn -pl <module> test -Dtest=XxxTest"
  echo "mvn -pl <module> -am test"
fi
if [ -x ./gradlew ]; then
  echo "./gradlew :<module>:test --tests 'com.example.XxxTest'"
  echo "./gradlew test"
elif has gradle; then
  echo "gradle :<module>:test --tests 'com.example.XxxTest'"
  echo "gradle test"
fi
