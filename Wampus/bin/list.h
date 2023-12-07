// list.h
#ifndef LIST_H
#define LIST_H

#include <stdbool.h>

typedef struct node {
    void* data;
    struct node *next;
} node;

bool _list_empty(node **head);

void _list_insert(node **head, unsigned int idx, void *data);

void _list_remove(node **head, unsigned int idx);

void *_list_at(node **head, int idx);

int _list_len(node **head);

#endif // LIST_H
