<script setup lang="ts">
import Button from 'openvue/button'

defineProps<{
  icon: string
  message: string
  actionLabel?: string
}>()

defineEmits<{ action: [] }>()
</script>

<template>
  <div
    class="flex flex-col items-center gap-3 rounded-lg border border-dashed border-[var(--p-content-border-color)] px-6 py-10 text-center"
  >
    <i :class="icon" class="text-2xl text-[var(--p-text-muted-color)]" />
    <p class="text-sm text-[var(--p-text-muted-color)]">{{ message }}</p>
    <Button v-if="actionLabel" :label="actionLabel" icon="oi oi-plus" size="small" @click="$emit('action')" />
  </div>
</template>
