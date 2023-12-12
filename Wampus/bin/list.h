// list.h
#ifndef LIST_H
#define LIST_H

#include <stdbool.h>

typedef struct node {
    void* data;
    struct node *next;
} node;

bool list_empty(node **head);

void list_insert(node **head, unsigned int idx, void *data);

void list_replace(node **head, unsigned int index, void *v);

void list_remove(node **head, unsigned int idx);

void *list_at(node **head, unsigned int idx);

void list_int_print(node **l);

unsigned int list_len(node **head);

#endif // LIST_H
