// Authors: Neil Powers, Christopher Sasanuma
// List implementation for wampus lists, provided to link with
// at compile time for programs.
// Stores lists under the hood as linked lists

#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <assert.h>
#include "list.h"
#include <string.h>

// typedef struct node {
//     void* data;
//     struct node *next;
// } node;

bool list_empty(node **head) {
    return head == NULL || *head == NULL;
}

node **list_insert(node **head, unsigned int idx, void *data) {
    unsigned int len = list_length(head); 

    assert((idx >= 0) && (idx <= len));
    
    node *curr = *head; 
    
    node *prev = NULL;
    
    // Finding insertion index
    for (unsigned int i = 0; i < idx; i++) {
        prev = curr;
        curr = curr->next;
    }

    // printf("Size of struct being allocated: %d \n", sizeof(*new_node));
    node *new_node = malloc(sizeof(*new_node)); 
    assert(new_node); 
    new_node->data = data; 
    new_node->next = curr;

    // If list is empty add to front, otherwise add to current location
    if (prev == NULL) { 
        *head = new_node;
    } else { 
        prev->next = new_node;
    }

    return head;
}

node **list_remove(node **head, unsigned int idx) {
    if (list_empty(head)) {
        return head;
    }

    node *curr = *head;
    node *prev = NULL;

    for (unsigned int i = 0; i < idx && curr != NULL; i++) {
        prev = curr;
        curr = curr->next;
    }

    if (curr == NULL) {
        return false;
    }

    if (prev == NULL) {
        *head = curr->next;
    } else {
        prev->next = curr->next;
    }
    free(curr);

    return head;
}

void *list_at(node **head, unsigned int idx) {
    assert(head && *head);

    node * curr = *head;

    for (unsigned int i = 0; i < idx; i++) {
        if (idx == 0) {
            return curr->data;
        }

        curr = curr -> next;

    }
    return curr -> data;
}

unsigned int list_length(node **head) {
    unsigned int len = 0;
    
    for (node *curr = *head; curr != NULL; curr = curr->next) {
        len++;
    }

    return len;
}

void list_int_print(node **l)
{
    if (!l || !*l) {
        printf("[]\n");
        return;
    }
    
    node *t = *l;
    int i = 0;
    int len = list_length(l);
    printf("[ ");
    while (i < len) {
        int *data = (int *)list_at(l, i); 
        printf("%d ", *data);
        t = t->next;
        i = i + 1;
    }
    printf("]\n");
}

node **list_replace(node **head, unsigned int index, void *v)
{
    assert(head && *head);
    unsigned int len = list_length(head); assert((index >= 0) && (index < len));

    node *curr = *head; void *old = NULL;
    for (unsigned int i = 0; i < index; i++) {
        curr = curr->next;
    }
    old = curr->data;
    curr->data = v;

    if (old) free(old);

    return head;
}

char *string_concat(char *s1, char *s2) {
    char *new = (char *) malloc(strlen(s1) + strlen(s2) + 1);
    strcpy(new, s1);
    strcat(new, s2);
    return new;
}

// Mallocs a new node with the given data and next pointer
#define NODE(val, next) ({ \
    node *n = malloc(sizeof(node)); \
    n->data = val; \
    n->next = next; \
    n; \
})

#define MVAL(n) ({ \
    int *v = malloc(sizeof(int)); \
    *v = n; \
    v; \
})

// static int main() {
//     node **head = malloc(sizeof(node *));
//     *head = NULL;

//     list_insert(head, 0, MVAL(1));
//     list_insert(head, 1, MVAL(2));

//     list_int_print(head);

//     list_remove(head, 0);

//     list_int_print(head);

//     list_insert(head, 0, MVAL(3));
//     list_insert(head, 0, MVAL(4));

//     list_int_print(head);

//     list_remove(head, 1);

//     list_int_print(head);

//     printf("Length: %d\n", list_length(head));
//     printf("At 0: %d\n", *(int *)list_at(head, 0));
//     printf("At 1: %d\n", *(int *)list_at(head, 1));

//     return 0;
// }