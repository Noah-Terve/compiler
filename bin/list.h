// Authors: Neil Powers, Christopher Sasanuma
// list.h

#ifndef LIST_H
#define LIST_H

#include <stdbool.h>

typedef struct node {
    void* data;
    struct node *next;
} node;

bool list_empty(node **head);

node **list_insert(node **head, unsigned int idx, void *data);

node **list_replace(node **head, unsigned int index, void *v);

node **list_remove(node **head, unsigned int idx);

void *list_at(node **head, unsigned int idx);

void list_int_print(node **l);

unsigned int list_length(node **head);

#endif // LIST_H
