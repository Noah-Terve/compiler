#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <assert.h>
#include "list.h"

// typedef struct node {
//     void data;
//     struct node *next;
// } node;

bool _list_empty(node **head) {
    return head == NULL || *head == NULL;
}

void _list_insert(node **head, int idx, void *data) {
        int* len = (int*) _list_len(head); 

        assert((idx >= 0) && (idx <= *len));
        
        node *curr = *head; 
        
        node *prev = NULL;
        
        // Finding insertion index
        for (int i = 0; i < idx; i++) {
            prev = curr;
            curr = curr->next;
        }

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

    int* len = malloc(sizeof(int));
    
    for (node *curr = *head; curr != NULL; curr = curr->next) {
        (*len)++;
    }

    printf("Length: %d\n", *len);

    return len;
}