# queues
Queues implemented by structs with a mutable list

Queue tools also are provided by (require data/queue)
The module presented in the present repository is very much alike,
but uses structs containing containing a mutable list plus two other fields:
the length of the mutable list and a pointer to the last element.
In fact the pointer is the last pair of the mutable list.
If the queue is empty the mutable list and the pointer are null.
Using a simplified description, the two elementary operations are as follows.
The first element is easily retrieved by taking the mcar of the mutable list
and removing it by replacing the list by its mcdr.
An element is added at the end by appending it to the pointer
and updating the pointer such as to point to the new element.
Both operations take constant time, independently of the length of the queue and the size of the data.

Because the elements of a queue have time order, indexed access is possible too,
but takes time proportional to the index.
