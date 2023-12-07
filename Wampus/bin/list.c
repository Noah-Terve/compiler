#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <assert.h>
#include "list.h"

// typedef struct node {
//     void* data;
//     struct node *next;
// } node;

bool _list_empty(node **head) {
    return head == NULL || *head == NULL;
}

void _list_insert(node **head, unsigned int idx, void *data) {

        int len = _list_len(head); 

        assert((idx >= 0) && (idx <= len));
        
        node *curr = *head; 
        
        node *prev = NULL;
        
        // Finding insertion index
        for (int i = 0; i < idx; i++) {
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
}

void _list_remove(node **head, unsigned int idx) {
    if (_list_empty(head)) {
        return;
    }

    node *curr = *head;
    node *prev = NULL;

    for (int i = 0; i < idx && curr != NULL; i++) {
        prev = curr;
        curr = curr->next;
    }

    if (curr == NULL) {
        return;
    }

    if (prev == NULL) {
        *head = curr->next;
    } else {
        prev->next = curr->next;
    }

    free(curr);
}

void *_list_at(node **head, int idx) {
    if (_list_empty(head)) {
        return NULL;
    }

    node * curr = *head;

    for (int i = 0; i < idx; i++) {
        if (idx == 0) {
            return curr->data;
        }

        curr = curr -> next;

    }
    return curr -> data;
}

int _list_len(node **head) {
    if (_list_empty(head)) {
        return 0;
    }

    int len = 0;
    // int* len = malloc(sizeof(int));
    
    for (node *curr = *head; curr != NULL; curr = curr->next) {
        len++;
    }

    // printf("Length: %d\n", len);

    return len;
}