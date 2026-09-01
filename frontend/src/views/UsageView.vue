<script setup lang="ts">
import { ref } from 'vue'
import Tabs from 'openvue/tabs'
import TabList from 'openvue/tablist'
import Tab from 'openvue/tab'
import TabPanels from 'openvue/tabpanels'
import TabPanel from 'openvue/tabpanel'
import { useI18n } from 'vue-i18n'
import { useProject } from '@/composables/useProject'
import ApiUsageView from './ApiUsageView.vue'
import LlmUsageView from './LlmUsageView.vue'
import TranslationUsageView from './TranslationUsageView.vue'

const { t } = useI18n()
const { project } = useProject()
const activeTab = ref('api')
</script>

<template>
  <div>
    <Tabs v-model:value="activeTab">
      <TabList>
        <Tab value="api">{{ t('usage.api.tab') }}</Tab>
        <Tab value="llm">{{ t('usage.llm.tab') }}</Tab>
        <Tab v-if="project" value="translations">{{ t('usage.translations.tab') }}</Tab>
      </TabList>
      <TabPanels>
        <TabPanel value="api">
          <ApiUsageView />
        </TabPanel>
        <TabPanel value="llm">
          <LlmUsageView />
        </TabPanel>
        <TabPanel v-if="project" value="translations">
          <TranslationUsageView />
        </TabPanel>
      </TabPanels>
    </Tabs>
  </div>
</template>
