#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>

typedef struct node {
    int data;
    struct node *next;
} node;

inline bool _list_empty(node **head) {
    return head == NULL || *head == NULL;
}

void _list_insert(node **head, int idx, void *data) {
    exit(1);
}

void _list_remove(node **head, int idx) {
    if (_list_empty(head)) {
        return;
    }

    for (node *curr = *head; curr != NULL; curr = curr->next) {
        if (idx == 0) {
            node *next = curr->next;
            free(curr);
            curr = next;
            return;
        }

        idx--;
    }

    return;
}

void *_list_at(node **head, int idx) {
    if (_list_empty(head)) {
        return NULL;
    }

    for (node *curr = *head; curr != NULL; curr = curr->next) {
        if (idx == 0) {
            return curr->data;
        }

        idx--;
    }

    return NULL;
}

void *_list_len(node **head) {
    if (_list_empty(head)) {
        return 0;
    }

    int len = 0;
    
    for (node *curr = *head; curr != NULL; curr = curr->next) {
        len++;
    }

    return len;
}