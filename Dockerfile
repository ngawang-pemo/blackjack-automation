FROM gcc:14.2 AS build

# Compile the blackjack program, same as in the previous tutorials
WORKDIR /app
COPY blackjack.c .
RUN gcc -static -o blackjack blackjack.c

# The final image is now Alpine Linux instead of "scratch".
# Our robot is made of shell scripts, so the image needs a shell (sh).
FROM alpine:3.20
ARG VERSION=1.0
LABEL version="${VERSION}"

WORKDIR /app
COPY --from=build /app/blackjack /app/blackjack
COPY play.sh simulate.sh leaderboard.sh ./
COPY strategies/ ./strategies/
# Windows can lose the "may be executed" flag, so set it again here
RUN chmod +x /app/*.sh

# play.sh looks here for the blackjack program
ENV BLACKJACK=/app/blackjack

# Run as a non-root user (65534 = "nobody")
USER 65534:65534

# docker run blackjack-bot:1.0                       -> default arguments below
# docker run blackjack-bot:1.0 smart 200             -> your own arguments
# docker run --entrypoint /app/leaderboard.sh ...    -> run the leaderboard instead
ENTRYPOINT ["/app/simulate.sh"]
CMD ["stand-on-16", "1000"]
