#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param) {
	
	// TODO: wait, obtain mutex, wait, release mutex as described by thread_data structure
	// hint: use a cast like the one below to obtain thread arguments from your parameter
    
	printf("Running threadfunc()\n");
	
	struct thread_data *data = (struct thread_data *)thread_param;
	usleep(data->wtime * 1000);
	pthread_mutex_lock(data->mutex);
	usleep(data->rtime * 1000);
	/* data->thread_complete_success = true; */
	pthread_mutex_unlock(data->mutex);
	data->thread_complete_success = true;
	
	printf("Exiting threadfunc()\n");
	
	return thread_param;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms) {
	/**
	 * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
	 * using threadfunc() as entry point.
	 *
	 * return true if successful.
	 *
	 * See implementation details in threading.h file comment block
	 */
	int ret;
	/* void *res; */
	
	struct thread_data *data = malloc(sizeof(struct thread_data));
	if (!data) {
		printf("%d\n", errno);
		return false;
	}
	
	data->mutex = mutex;		
	data->wtime = wait_to_obtain_ms;
	data->rtime = wait_to_release_ms;
	/* data->thread_complete_success = false; */

	printf("Going to run pthread_create()\n");
	
	ret = pthread_create(thread, NULL, threadfunc, data);	
	if (ret) {
		printf("%d\n", errno);
		free(data);
		return false;
	}


	printf("Successfully created thread %p\n", thread);

	/* ret = pthread_join(*thread, &res);
	if (ret) {
		printf("%d\n", errno);
		free(data);
		return false;
	}

	printf("Successfully joined with %p; returned value was %d\n", thread, ((struct thread_data *)res)->thread_complete_success); */

	/* pthread_mutex_lock(mutex); */
	/* if (data->thread_complete_success == false) { */
		/* pthread_mutex_unlock(mutex); */
		/* printf("thread_complete_success is false\n");
		free(data); */
		/* free(res); */
		/* return false; */
	} 
	/* pthread_mutex_unlock(mutex); */
	
	printf("thread_complete_success is true\n");
	free(data);
	/* free(res); */
	return true;
}
