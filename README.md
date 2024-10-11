[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]

# OpenRewrite, AOT and CDS

## The cheat code

```bash
./mvnw -U org.openrewrite.maven:rewrite-maven-plugin:run \
 -Drewrite.recipeArtifactCoordinates=org.openrewrite.recipe:rewrite-spring:LATEST \
 -DactiveRecipes=org.openrewrite.java.spring.boot3.UpgradeSpringBoot_3_3
```

## The Spoiler

```text
#### Comparison of memory usage and startup times

Configuration                       Startup Time (seconds)    (MB) Used       (MB) Savings
--------------------------------------------------------------------------------------------
Spring Boot 2.6 with Java 8         1.018                     340.6           -
Spring Boot 3.3 with Java 23        1.014 (1.00% faster)      239.3           30.00% 
Spring Boot 3.3 extracted           0.867 (15.00% faster)     210.6           39.00% 
Spring Boot 3.3 with AOT processing 0.765 (25.00% faster)     205.7           40.00% 
Spring Boot 3.3 with CDS            0.568 (45.00% faster)     208.2           39.00% 
Spring Boot 3.3 with AOT+CDS        0.383 (63.00% faster)     165.5           52.00% 
--------------------------------------------------------------------------------------------
```
> Does that look too good to be true?  Run the demo and see for yourself!

## Prerequisites
- [SDKMan](https://sdkman.io/install)
  > i.e. `curl -s "https://get.sdkman.io" | bash`
- [Httpie](https://httpie.io/) needs to be in the path
  > i.e. `brew install httpie`
- bc, pv, zip, unzip, gcc, zlib1g-dev
  > i.e. `sudo apt install bc, pv, zip, unzip, gcc, zlib1g-dev -y`
- [Vendir](https://carvel.dev/vendir/)
  > i.e. `brew tap carvel-dev/carvel && brew install vendir`

## Quick Start
```bash
./demo.sh
```

## Attributions
- [Demo Magic](https://github.com/paxtonhare/demo-magic) is pulled via `vendir sync`

## References

- [Spring Boot CDS Support and Project Leyden anticipation](https://spring.io/blog/2024/08/29/spring-boot-cds-support-and-project-leyden-anticipation)
- [AOT processing](https://docs.spring.io/spring-boot/reference/packaging/aot.html)

## Related Videos

- https://www.youtube.com/live/qQAXXwkaveM?si=4KunXZaretBrPZs3
- https://www.youtube.com/live/ck4AP7kRQkc?si=lDl203vbfZysrX5e
- https://www.youtube.com/live/VWPrYcyjG8Q?si=z7Q2Rm_XOlBwCiei

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[forks-shield]: https://img.shields.io/github/forks/dashaun/openrewrite-aot-cds.svg?style=for-the-badge
[forks-url]: https://github.com/dashaun/openrewrite-aot-cds/forks
[stars-shield]: https://img.shields.io/github/stars/dashaun/openrewrite-aot-cds.svg?style=for-the-badge
[stars-url]: https://github.com/dashaun/openrewrite-aot-cds/stargazers
[issues-shield]: https://img.shields.io/github/issues/dashaun/openrewrite-aot-cds.svg?style=for-the-badge
[issues-url]: https://github.com/dashaun/openrewrite-aot-cds/issues
