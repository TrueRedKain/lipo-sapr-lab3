

#ifndef _stack_h
#define _stack_h

typedef struct {
    int *ptr;
    size_t size;
    size_t count;
} c_stack;

void c_stack_init(c_stack* stack, size_t size);
void c_stack_done(c_stack* stack);

void c_stack_push(c_stack* stack, int value);
int c_stack_pull(c_stack* stack);

void c_stack_clean(c_stack* stack);
int c_stack_count(c_stack* stack);

int c_stack_get_deep(c_stack* stack, int index);

int c_stack_top(c_stack* stack);
int c_stack_is_empty(c_stack* stack);
int c_stack_is_full(c_stack* stack);

#endif
