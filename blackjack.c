#include <stdio.h>
#include <stdlib.h>
#include <time.h>

/* Blackjack, simplified:
   - You and the dealer each get two cards. You only see one dealer card.
   - Hit (h) to take one more card, or stand (s) to stop.
   - If your cards add up to exactly 21, you win right away.
   - If you go over 21, you lose (bust).
   - When you stand, the dealer draws cards until reaching 17 or more.
     Then the higher total wins. If the dealer goes over 21, you win.
   Cards: A counts 1 or 11, J Q K count 10, the others count their number.
   The deck never runs out.

   The cards are "random", but they come from a seed number. The same seed
   always gives the same cards. So the program does not need to remember
   anything: give it the seed and the moves so far (like "hh"), and it
   replays the game from the start. */

#define MAX_CARDS 64
#define DEALER_STANDS_ON 19

static unsigned long deck_state;

/* Draw the next card (1 = ace, 2-10, 11 = jack, 12 = queen, 13 = king).
   This is a tiny random number generator. Same seed, same cards. */
static int draw(void) {
    deck_state = (deck_state * 1103515245UL + 12345UL) & 0xFFFFFFFFUL;
    return (int)(((deck_state >> 16) & 0x7FFF) % 13) + 1;
}

/* Add up a hand. An ace counts 11 when that does not push the hand over 21. */
static int total(const int *cards, int count) {
    int sum = 0, aces = 0, i;
    for (i = 0; i < count; i++) {
        if (cards[i] == 1) {
            aces++;
        }
        sum += cards[i] > 10 ? 10 : cards[i];
    }
    if (aces > 0 && sum + 10 <= 21) {
        sum += 10;
    }
    return sum;
}

static void print_card(int card) {
    if (card == 1) {
        printf("A");
    } else if (card == 11) {
        printf("J");
    } else if (card == 12) {
        printf("Q");
    } else if (card == 13) {
        printf("K");
    } else {
        printf("%d", card);
    }
}

static void print_hand(const int *cards, int count) {
    int i;
    for (i = 0; i < count; i++) {
        if (i > 0) {
            printf(" ");
        }
        print_card(cards[i]);
    }
}

/* Replays the game from the seed and the moves so far, then prints one line.
   Returns 0 if the game goes on, 1 if it is over,
   or 2 if there was a move after the game had already ended. */
static int play(unsigned long seed, const char *moves) {
    int you[MAX_CARDS], dealer[MAX_CARDS];
    int you_count = 0, dealer_count = 0, i;
    int over = 0;
    const char *result = "";

    /* The deal: you, dealer, you, dealer */
    deck_state = seed;
    you[you_count++] = draw();
    dealer[dealer_count++] = draw();
    you[you_count++] = draw();
    dealer[dealer_count++] = draw();

    if (total(you, you_count) == 21) {
        over = 1;
        result = "21! You win!";
    }

    for (i = 0; moves[i] != '\0'; i++) {
        if (over) {
            return 2;
        }
        if (moves[i] == 'h') {
            /* Hit: you take one more card */
            you[you_count++] = draw();
            if (total(you, you_count) > 21) {
                over = 1;
                result = "Bust! You lose.";
            } else if (total(you, you_count) == 21) {
                over = 1;
                result = "21! You win!";
            }
        } else {
            /* Stand: now the dealer plays */
            while (total(dealer, dealer_count) < DEALER_STANDS_ON) {
                dealer[dealer_count++] = draw();
            }
            over = 1;
            if (total(dealer, dealer_count) > 21) {
                result = "Dealer busts! You win!";
            } else if (total(you, you_count) > total(dealer, dealer_count)) {
                result = "You win!";
            } else if (total(you, you_count) < total(dealer, dealer_count)) {
                result = "Dealer wins.";
            } else {
                result = "Draw.";
            }
        }
    }

    /* One line: your cards | the dealer's cards | what happens next */
    printf("You: ");
    print_hand(you, you_count);
    printf(" (%d) | Dealer: ", total(you, you_count));
    if (over) {
        print_hand(dealer, dealer_count);
        printf(" (%d)", total(dealer, dealer_count));
    } else {
        /* The second dealer card stays hidden until the end */
        print_card(dealer[0]);
        printf(" ?");
    }
    printf(" | %s\n", over ? result : "Hit or stand?");
    return over;
}

/* Convert text to a whole number. Returns 1 if OK, 0 if the text is not a number. */
static int parse(const char *text, long *out) {
    char *end;
    long value = strtol(text, &end, 10);
    /* Keep huge numbers small */
    if (value > 999999999L) value = 999999999L;
    if (value < -999999999L) value = -999999999L;
    *out = value;
    return end != text && *end == '\0';
}

int main(int argc, char *argv[]) {
    long seed;
    int i, status;
    const char *moves;

    if (argc == 2 || argc == 3) {
        /* One step: ./blackjack <seed> [moves] */
        moves = argc == 3 ? argv[2] : "";
        if (!parse(argv[1], &seed)) {
            fprintf(stderr, "Error: the seed must be a whole number.\n");
            return 1;
        }
        for (i = 0; moves[i] != '\0'; i++) {
            if (moves[i] != 'h' && moves[i] != 's') {
                fprintf(stderr, "Error: moves can only contain h (hit) and s (stand).\n");
                return 1;
            }
        }
        if (seed < 0) {
            fprintf(stderr, "Error: the seed cannot be negative.\n");
            return 2;
        }
        if (play((unsigned long)seed, moves) == 2) {
            fprintf(stderr, "Error: the game is already over, no more moves are allowed.\n");
            return 2;
        }
        return 0;
    }

    if (argc > 3) {
        fprintf(stderr, "Usage: blackjack <seed> [moves]\n");
        return 1;
    }

    /* No arguments: play the whole game in the terminal with a new seed each time */
    {
        char history[128] = "";
        int length = 0;
        char key;

        seed = (long)(time(NULL) % 1000000);
        printf("Blackjack: reach 21 to win, go over 21 and you lose.\n");
        status = play((unsigned long)seed, history);
        while (status == 0) {
            printf("Hit (h) or stand (s)? ");
            fflush(stdout);
            if (scanf(" %c", &key) != 1) {
                fprintf(stderr, "Invalid input.\n");
                return 1;
            }
            if (key != 'h' && key != 's') {
                printf("Type h or s.\n");
                continue;
            }
            history[length++] = key;
            history[length] = '\0';
            status = play((unsigned long)seed, history);
        }
    }
    return 0;
}
