
#include <stdlib.h>
#include "mystack.h"

void c_stack_init(c_stack* stack, size_t size)
{
    stack->size = size;
    stack->count = 0;
    stack->ptr = calloc(stack->size, sizeof(int));
}

void c_stack_done(c_stack* stack)
{
    stack->size = 0;
    stack->count = 0;
    free(stack->ptr);
}

void c_stack_push(c_stack* stack, int value)
{
    if (stack->count >= stack->size) {
        return;
    }
    stack->ptr[stack->count++] = value;
}

int c_stack_pull(c_stack* stack)
{
    if (stack->count == 0) {
        return -1;
    }
    return stack->ptr[--stack->count];
}

void c_stack_clean(c_stack* stack) 
{
    stack->count = 0;
}

int c_stack_count(c_stack* stack)
{
    return stack->count;
}

int c_stack_get_deep(c_stack* stack, int index)
{
    if (stack->count == 0) {
        return -1;
    }
    return stack->ptr[stack->count -  index];
}

int c_stack_top(c_stack* stack)
{
    if (stack->count == 0) {
        return -1;
    }
    return stack->ptr[stack->count];
}

int c_stack_is_empty(c_stack* stack)
{
    return stack->count == 0;
}

int c_stack_is_full(c_stack* stack)
{
    return stack->count >= stack->size;
}
