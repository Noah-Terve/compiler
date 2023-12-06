#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <assert.h>
#include "../../bin/list.h"

void test_list_empty(node **head, bool expected) {
    assert(_list_empty(head) == expected);
}

void test_list_len(node **head, int expected) {
    assert(*(int*)_list_len(head) == expected);
}

int main() {
    // Create an empty linked list
    node* head = NULL;

    // Test _list_empty function
    test_list_empty(&head, true);

    // Insert elements into the linked list
    _list_insert(&head, 0, (void*)10);
    _list_insert(&head, 1, (void*)20);
    _list_insert(&head, 2, (void*)30);

    // Test _list_empty function again
    test_list_empty(&head, false);

    // Test _list_len function
    test_list_len(&head, 3);

    // Test _list_at function
    int currLength = *(int*)_list_len(&head);
    
    for (int i = 0; i < currLength ; ++i) {
        printf("Element at index %d: %d\n", i, *(int*)_list_at(&head, i));
    }

    // Test _list_remove function
    _list_remove(&head, 1);

    // Test _list_len function after removal
    test_list_len(&head, 2);

    // Free the remaining elements
    while (!_list_empty(&head)) {
        printf("Removing element: %d\n", *(int*)_list_at(&head, 0));
        _list_remove(&head, 0);
    }

    // Test _list_empty function after removal
    test_list_empty(&head, true);

    return 0;
}